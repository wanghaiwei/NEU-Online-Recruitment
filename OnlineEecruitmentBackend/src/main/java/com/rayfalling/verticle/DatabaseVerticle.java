package com.Rayfalling.verticle;

import com.Rayfalling.Shared;
import io.reactiverse.pgclient.PgPoolOptions;
import io.reactiverse.reactivex.pgclient.PgPool;
import io.reactivex.Single;
import io.vertx.core.Promise;
import io.vertx.reactivex.core.AbstractVerticle;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jetbrains.annotations.NotNull;

/**
 * 数据库实例
 */
@SuppressWarnings("ResultOfMethodCallIgnored")
public class DatabaseVerticle extends AbstractVerticle {
    private final Logger logger = LogManager.getLogger("Database");
    
    @Override
    public void start(@NotNull Promise<Void> startPromise) throws Exception {
        Single.just(config()).flatMap(config -> {
            PgPoolOptions options = new PgPoolOptions();
            options.setHost(config.getString("host"))
                   .setPort(config.getInteger("port"))
                   .setDatabase(config.getString("database"))
                   .setUser(config.getString("username"))
                   .setPassword(config.getString("password"))
                   .setMaxSize(config.getInteger("pool_size"));
            PgPool db = PgPool.pool(Shared.getVertx(), options);
            Shared.setPgPool(db);
            
            return Single.just(config);
        }).doOnSubscribe(res -> {
            logger.info("Creating Postgresql connection pool...");
        }).doAfterSuccess(res -> {
            logger.info("Pool creation successful.");
        }).subscribe(res -> {
            startPromise.complete();
        }, startPromise::fail);
    }
    
    @Override
    public void stop(@NotNull Promise<Void> stopPromise) throws Exception {
        Single.just(Shared.getPgPool()).map(pool -> {
            pool.close();
            
            return null;
        }).doOnSubscribe(res -> {
            logger.info("Starting close PgPool...");
        }).doOnSuccess(res -> {
            logger.info("Pool closed successful.");
        }).subscribe(res -> {
            stopPromise.complete();
        }, stopPromise::fail);
    }
}
