package com.Rayfalling.verticle;

import com.Rayfalling.Shared;
import com.Rayfalling.router.MainRouter;
import io.reactivex.Single;
import io.vertx.reactivex.core.AbstractVerticle;
import io.vertx.reactivex.core.Promise;
import io.vertx.reactivex.core.http.HttpServer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


/**
 * 主启动类
 */
@SuppressWarnings("ResultOfMethodCallIgnored")
public class MainVerticle extends AbstractVerticle {
    private Logger logger = LogManager.getLogger("MainVerticle");
    
    @Override
    public void stop() {
        InnerStop(Promise.promise());
    }
    
    @Override
    public void start() {
        InnerStart(Promise.promise());
    }
    
    // Called when verticle is deployed
    private void InnerStart(Promise<Void> startPromise) {
        final String listenHost = config().getString("host");
        final Integer listenPort = config().getInteger("port");
        HttpServer server = vertx.createHttpServer();
        Shared.setHttpServer(server);
        server.requestHandler(MainRouter.getInstance().getRouter())
              .rxListen(listenPort, listenHost)
              .doOnError(error -> {
                  logger.fatal("Failed to listen at host " + listenHost + " port " + listenPort);
                  error.printStackTrace();
              })
              .doOnSubscribe(res -> {
                  logger.info("VerticleInstance: " +
                              Thread.currentThread().getId() +
                              ". Creating Http Server...");
              })
              .doAfterSuccess(res -> {
                  logger.info("VerticleInstance: " +
                              Thread.currentThread().getId() +
                              ". Server listened at host " + listenHost + " port " + listenPort);
              })
              .subscribe(res -> {
                  startPromise.complete();
              }, startPromise::fail);
    }
    
    // Called when verticle is undeploy
    private void InnerStop(Promise<Void> stopPromise) {
        Single.just(Shared.getHttpServer()).map(httpServer -> {
            httpServer.close();
            
            return null;
        }).doOnSubscribe(res -> {
            logger.info("Starting close HttpServer...");
        }).doOnSuccess(res -> {
            logger.info("HttpServer closed successful.");
        }).subscribe(res -> {
            stopPromise.complete();
        }, stopPromise::fail);
    }
}