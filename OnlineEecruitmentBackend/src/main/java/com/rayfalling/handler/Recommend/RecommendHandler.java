package com.Rayfalling.handler.Recommend;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Extensions.DataBaseExt;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Utils.Recommend.RecommendUtils;
import com.Rayfalling.middleware.Utils.sql.SqlQuery;
import com.Rayfalling.middleware.data.Recommend.*;
import com.Rayfalling.middleware.data.TimerEvent;
import com.Rayfalling.verticle.TimerVerticle;
import io.reactiverse.reactivex.pgclient.Tuple;
import io.reactiverse.reactivex.pgclient.data.Json;
import io.reactivex.Single;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jetbrains.annotations.NotNull;

import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import static com.Rayfalling.handler.DatabaseConnection.PgConnectionSingle;


@SuppressWarnings("ResultOfMethodCallIgnored")
public class RecommendHandler {
    private final static Logger logger = LogManager.getLogger("TimerHandler");
    
    /**
     * 自动保存函数
     */
    private static final TimerEvent AutoSave = () -> {
        List<Tuple> mapTuples = new LinkedList<>();
        RecommendMapStorage.getRecommendMapList().forEach(item -> {
            mapTuples.add(Tuple.of(item.getSourceId(), item.getNextId(), item.getHitCount()));
        });
        
        List<Tuple> userTuples = new LinkedList<>();
        RecommendUserStorage.getRecommendUsers().forEach(item -> {
            mapTuples.add(Tuple.of(item.getUserId(), item.getWeight().encode()));
        });
        
        PgConnectionSingle().flatMap(conn -> conn.rxPreparedBatch(SqlQuery.getQuery("RecommendSaveMap"), mapTuples))
                            .doOnError(err -> {
                                logger.error(err);
                                err.printStackTrace();
                            })
                            .doAfterSuccess(res -> {
                                logger.error("Auto save map success");
                            }).subscribe();
        
        PgConnectionSingle().flatMap(conn -> conn.rxPreparedBatch(SqlQuery.getQuery("RecommendSaveUser"), userTuples))
                            .doOnError(err -> {
                                logger.error(err);
                                err.printStackTrace();
                            })
                            .doAfterSuccess(res -> {
                                logger.error("Auto save user weight success");
                            }).subscribe();
    };
    
    /**
     * 自动加载数据库最新的职位
     */
    private static final TimerEvent AutoLoadPosition = () -> {
        PgConnectionSingle().flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("RecommendLoadPosition")))
                            .flatMap(pgRowSet -> {
                                pgRowSet.forEach(row -> {
                                    PositionStorage
                                            .add(new Position(row.getInteger("id"),
                                                    row.getInteger("position_category_id"),
                                                    row.getLocalDateTime("post_time")));
                                });
                                return Single.just(pgRowSet);
                            })
                            .doOnError(err -> {
                                logger.error(err);
                                err.printStackTrace();
                            })
                            .doAfterSuccess(res -> {
                                Shared.getVertx().executeBlocking(promise -> {
                                    PositionStorage.RemoveOutdated();
                                }, result -> {
                                    logger.info("Resize recommend pool");
                                });
                            }).subscribe();
        
        
    };
    
    public static void RegisterRecommendTimer() {
        TimerVerticle.register(AutoSave).subscribe(res -> {
            logger.info("Register timer for recommendation auto save successful");
        }, err -> {
            logger.error("Register timer for recommendation auto save failed");
        });
        TimerVerticle.register(AutoLoadPosition).subscribe(res -> {
            logger.info("Register timer for recommendation auto load successful");
        }, err -> {
            logger.error("Register timer for recommendation auto load failed");
        });
        
        //读取数据库用户推荐权重
        //延迟加载保障数据库连接可用
        Single.just(true).delay(2000L, TimeUnit.MILLISECONDS).flatMap(res -> {
            LoadUserWeight();
            AutoLoadPosition.event();
            return Single.just(res);
        }).subscribe();
    }
    
    /**
     * 获取用户权重
     */
    private static void LoadUserWeight() {
        PgConnectionSingle().flatMap(conn -> {
            return conn.rxPreparedQuery(SqlQuery.getQuery("RecommendLoadUser"));
        }).map(pgRowSet -> {
            pgRowSet.forEach(row -> {
                if (!RecommendUserStorage.exist(row.getInteger("user_id"))) {
                    Object json = row.getJson("recommend").value();
                    RecommendUserStorage.add(new RecommendUser(row.getInteger("user_id"), JsonObject.mapFrom(json)));
                } else {
                    RecommendUserStorage.find(row.getInteger("user_id"))
                                        .updateWeight(JsonObject.mapFrom(row.getJson("recommend")));
                }
            });
            return pgRowSet;
        }).doOnError(err -> {
            logger.error(err);
            err.printStackTrace();
        }).subscribe();
    }
    
    /**
     * 更新用户权重值
     *
     * @param userId   用户Id
     * @param category 浏览分类
     * @param second   浏览时长
     */
    public static void UpdateUserWeight(int userId, int category, int second) {
        if (!RecommendUserStorage.exist(userId)) {
            RecommendUser user = new RecommendUser(userId, new JsonObject().put(String.valueOf(category), 0.5));
            RecommendUserStorage.add(user);
        }
        RecommendUser recommendUser = RecommendUserStorage.find(userId);
        JsonObject weight = recommendUser.getWeight();
        recommendUser.updateWeight(RecommendUtils.RecomputeWeight(weight, category, second));
    }
    
    /**
     * 更新职位关系映射表
     */
    public static void UpdatePositionMap(int previous, int next) {
        if (RecommendMapStorage.exist(previous, next))
            RecommendMapStorage.find(previous, next).hit();
        else RecommendMapStorage.add(new RecommendMap(previous, next, 1));
    }
    
    /**
     * 获取推荐列表
     *
     * @param userId 用户Id
     */
    public static Single<JsonArray> Recommend(int userId, int positionId) {
        JsonObject weight;
        if (userId == -1) {
            weight = createNewWeight();
        } else {
            if (RecommendUserStorage.exist(userId))
                weight = RecommendUserStorage.find(userId).getWeight();
            else {
                weight = createNewWeight();
                RecommendUser recommendUser = new RecommendUser(userId, weight);
                RecommendUserStorage.add(recommendUser);
            }
        }
        
        List<Position> RecommendList = RecommendUtils.generateRecommendList(weight, positionId);
        JsonArray RecommendId = new JsonArray();
        for (Position position : RecommendList) {
            RecommendId.add(position.getId());
        }
        
        return PgConnectionSingle().flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("RecommendList"),
                Tuple.of(DataBaseExt.getQueryString(RecommendId))))
                                   .map(pgRowSet -> {
                                       return DataBaseExt.mapJsonArray(pgRowSet, row -> {
                                           return new JsonObject().put("id", row.getInteger("id"))
                                                                  .put("name", row.getString("name"))
                                                                  .put("grade", row.getInteger("grade"))
                                                                  .put("company", row.getString("company"))
                                                                  .put("location", row.getString("location"))
                                                                  .put("post_mail", row.getString("post_mail"))
                                                                  .put("description", row.getString("description"))
                                                                  .put("post_time", DataBaseExt
                                                                                            .getLocalDateTimeToTimestamp(row, "description"))
                                                                  .put("position_category_id", row.getString("position_category_id"));
                                       });
                                   })
                                   .doOnError(err -> {
                                       Shared.getDatabaseLogger().error(err);
                                       err.printStackTrace();
                                   });
    }
    
    /**
     * 创建新的用户权值
     * 默认用户喜好为平均分配
     */
    private static @NotNull JsonObject createNewWeight() {
        JsonObject weight = new JsonObject();
        List<Integer> categoryList = PositionStorage.getPositionList().parallelStream()
                                                    .map(Position::getLabel)
                                                    .distinct().collect(Collectors.toList());
        for (Integer integer : categoryList) {
            weight.put(String.valueOf(integer), 1.0f / categoryList.size());
        }
        return weight;
    }
}
