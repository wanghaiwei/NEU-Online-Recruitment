package com.Rayfalling.verticle;

import com.Rayfalling.Shared;
import com.Rayfalling.config.MainRouterConfig;
import com.Rayfalling.middleware.Utils.Security.EncryptUtils;
import com.Rayfalling.router.MainRouter;
import io.reactivex.Single;
import io.vertx.core.Promise;
import io.vertx.reactivex.core.AbstractVerticle;
import io.vertx.reactivex.core.http.HttpServer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jetbrains.annotations.NotNull;


/**
 * 主启动类
 */
@SuppressWarnings("ResultOfMethodCallIgnored")
public class MainVerticle extends AbstractVerticle {
    private final Logger logger = LogManager.getLogger("MainVerticle");
    
    @Override
    public void start(@NotNull Promise<Void> startPromise) {
        final String listenHost = config().getString("host");
        final Integer listenPort = config().getInteger("port");
        HttpServer server = vertx.createHttpServer();
        EncryptUtils.setKey(MainRouterConfig.getInstance().getTokenSalt());
        Shared.setHttpServer(server);
        server.requestHandler(MainRouter.getRouter())
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
    
    @Override
    public void stop(@NotNull Promise<Void> stopPromise) {
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