package com.rayfalling.verticle;

import com.rayfalling.Shared;
import com.rayfalling.router.MainRouter;
import io.vertx.core.Future;
import io.vertx.rxjava.core.AbstractVerticle;

import io.vertx.rxjava.core.Promise;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import rx.Completable;

/**
 * 主启动类
 */
public class MainVerticle extends AbstractVerticle {
    private Logger logger = LogManager.getLogger("MainVerticle");

    // Called when verticle is deployed
    public void start(Future<Void> startFuture) {
        String listenHost = config().getString("host");
        Integer listenPort = config().getInteger("port");
        Shared.getInstance().getVertx().createHttpServer().requestHandler(MainRouter.getInstance().getRouter())
              .rxListen(listenPort, listenHost)
              .doOnError(error -> { logger.fatal("Failed to listen at host `$listenHost` port $listenPort"); })
              .doOnSuccess(res -> { logger.debug("Listen succeeded at host `$listenHost` port $listenPort."); })
              .subscribe(res -> {
                  Promise.promise().complete();
              }, Completable::error);
    }

    // Optional - called when verticle is undeployed
    public void stop() {
    }
}