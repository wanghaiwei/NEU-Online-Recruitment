package com.rayfalling.verticle;

import com.rayfalling.Shared;
import com.rayfalling.router.MainRouter;
import io.vertx.core.Future;
import io.vertx.rxjava.core.AbstractVerticle;

import io.vertx.rxjava.core.Promise;
import io.vertx.rxjava.core.http.HttpServer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import rx.Completable;
import rx.Single;

/**
 * 主启动类
 */
public class MainVerticle extends AbstractVerticle {
    private Logger logger = LogManager.getLogger("MainVerticle");

    // Called when verticle is deployed
    public void start(Future<Void> startFuture) {
        String listenHost = config().getString("host");
        Integer listenPort = config().getInteger("port");
        HttpServer server = Shared.getInstance().getVertx().createHttpServer();
        Shared.getInstance().setHttpServer(server);
        server.requestHandler(MainRouter.getInstance().getRouter())
              .rxListen(listenPort, listenHost)
              .doOnError(error -> { logger.fatal("Failed to listen at host `$listenHost` port $listenPort"); })
              .doOnSuccess(res -> { logger.debug("Listen succeeded at host `$listenHost` port $listenPort."); })
              .subscribe(res -> {
                  Promise.promise().complete();
              }, Completable::error);
    }

    @Override
    public void stop(Future<Void> stopFuture) throws Exception {
        Single.just(Shared.getInstance().getHttpServer()).map(httpServer ->{
            httpServer.close();

            return null;
        }).doOnSubscribe(() -> {
            logger.info("Starting close HttpServer...");
        }).doOnSuccess(res -> {
            logger.info("HttpServer closed successful.");
        }).subscribe(res -> {
            Promise.promise().complete();
        }, Completable::error);
    }
}