package com.Rayfalling.handler.Recommend;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Utils.sql.SqlQuery;
import com.Rayfalling.middleware.data.Recommend.Position;
import com.Rayfalling.middleware.data.Recommend.PositionStorage;
import com.Rayfalling.middleware.data.Recommend.RecommendMapStorage;
import com.Rayfalling.middleware.data.Recommend.RecommendUserStorage;
import io.reactiverse.reactivex.pgclient.Tuple;
import io.reactivex.Single;
import io.vertx.core.Handler;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.LinkedList;
import java.util.List;

import static com.Rayfalling.handler.DatabaseConnection.PgConnectionSingle;


@SuppressWarnings("ResultOfMethodCallIgnored")
public class RecommendHandler {
    private final static Logger logger = LogManager.getLogger("TimerHandler");
    
    /**
     * 自动保存函数
     */
    private static final Handler<Long> AutoSave = id -> {
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
                            });
        
        PgConnectionSingle().flatMap(conn -> conn.rxPreparedBatch(SqlQuery.getQuery("RecommendSaveUser"), userTuples))
                            .doOnError(err -> {
                                logger.error(err);
                                err.printStackTrace();
                            });
    };
    
    /**
     * 自动加载数据库最新的职位
     */
    private static final Handler<Long> AutoLoadPosition = id -> {
        PgConnectionSingle().flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("RecommendLoadPosition")))
                            .flatMap(pgRowSet -> {
                                pgRowSet.forEach(row -> {
                                    PositionStorage
                                            .add(new Position(row.getInteger("id"), row.getInteger("position_category_id")));
                                });
                                return Single.just(pgRowSet);
                            })
                            .doOnError(err -> {
                                logger.error(err);
                                err.printStackTrace();
                            });
    };
    
    public static void RegisterRecommendTimer() {
        Shared.getVertx().eventBus().<Handler<Void>>request("register.timer", AutoSave, result -> {
            if (result.succeeded()) {
                logger.info("Register timer for recommendation auto save successful");
            } else {
                logger.error("Register timer for recommendation auto save failed");
            }
        });
        Shared.getVertx().eventBus().<Handler<Void>>request("register.timer", AutoLoadPosition, result -> {
            if (result.succeeded()) {
                logger.info("Register timer for recommendation auto load successful");
            } else {
                logger.error("Register timer for recommendation auto load failed");
            }
        });
        //todo 读取推荐系统参数
    }
}
