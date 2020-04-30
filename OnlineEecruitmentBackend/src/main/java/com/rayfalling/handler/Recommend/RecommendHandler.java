package com.Rayfalling.handler.Recommend;

import com.Rayfalling.Shared;
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

import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.TimeUnit;

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
    
    //TODO 实现推荐权重计算和推荐
    
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
        if (second >= 5) {
            recommendUser.updateWeight(RecommendUtils.RecomputeWeight(weight, category, second));
        }
    }
    
    /**
     * 更新职位关系映射表
     */
    public static void UpdatePositionMap(int previous, int next) {
        RecommendMapStorage.find(previous, next).hit();
    }
    
    /**
     * 获取推荐列表
     * @param userId   用户Id
     */
    public static Single<JsonArray> Recommend(int userId) {
    //todo here
        return Single.just(new JsonArray());
    }
}
