package com.rayfalling.verticle;

import com.rayfalling.Shared;
import io.reactiverse.pgclient.PgPoolOptions;
import io.reactiverse.rxjava.pgclient.PgPool;
import io.vertx.core.Future;
import io.vertx.rxjava.core.AbstractVerticle;
import io.vertx.rxjava.core.Promise;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import rx.Completable;
import rx.Single;

public class DatabaseVerticle extends AbstractVerticle {
    private Logger logger = LogManager.getLogger(this);

    @Override
    public void start(Future<Void> startFuture) {
        Single.just(config()).map(config -> {
            PgPoolOptions options = new PgPoolOptions();
            options.setHost(config.getString("host"))
                   .setPort(config.getInteger("port"))
                   .setDatabase(config.getString("database"))
                   .setUser(config.getString("username"))
                   .setPassword(config.getString("password"))
                   .setMaxSize(config.getInteger("pool_size"));
            PgPool db = PgPool.pool(Shared.getInstance().getVertx(), options);
            Shared.getInstance().setPgPool(db);

            return null;
        }).doOnSubscribe(() -> {
            logger.info("Creating PostgreSQL connection pool...");
        }).doOnSuccess(res -> {
            logger.info("Pool creation successful.");
        }).subscribe(res -> {
            Promise.promise().complete();
        }, Completable::error);
    }

    @Override
    public void stop(Future<Void> stopFuture) throws Exception {
        Single.just(Shared.getInstance().getPgPool()).map(pool ->{
            pool.close();

            return null;
        }).doOnSubscribe(() -> {
            logger.info("Starting close PgPool...");
        }).doOnSuccess(res -> {
            logger.info("Pool closed successful.");
        }).subscribe(res -> {
            Promise.promise().complete();
        }, Completable::error);
    }
}
