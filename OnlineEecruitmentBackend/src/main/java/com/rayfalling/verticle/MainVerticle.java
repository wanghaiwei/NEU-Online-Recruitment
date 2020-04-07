package com.Rayfalling.verticle;

import com.Rayfalling.Shared;
import com.Rayfalling.router.MainRouter;
import io.reactivex.Single;
import io.vertx.core.Future;
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
    
    // Called when verticle is deployed
    public void start(Future<Void> startFuture) {
        String listenHost = config().getString("host");
        Integer listenPort = config().getInteger("port");
        HttpServer server = Shared.getInstance().getVertx().createHttpServer();
        Shared.getInstance().setHttpServer(server);
        server.requestHandler(MainRouter.getInstance().getRouter())
              .rxListen(listenPort, listenHost)
              .doOnError(error -> {
                  logger.fatal("Failed to listen at host `$listenHost` port " + listenPort);
                  error.printStackTrace();
              })
              .doOnSuccess(res -> {
                  logger.debug("Listen succeeded at host `$listenHost` port " + listenPort);
              })
              .subscribe(res -> {
                  Promise.promise().complete(res);
              }, failure -> {
                  Promise.promise().fail(failure);
              });
    }
    
    @Override
    public void stop(Future<Void> stopFuture) throws Exception {
        Single.just(Shared.getInstance().getHttpServer()).map(httpServer -> {
            httpServer.close();
            
            return null;
        }).doOnSubscribe(res -> {
            logger.info("Starting close HttpServer...");
        }).doOnSuccess(res -> {
            logger.info("HttpServer closed successful.");
        }).subscribe(res -> {
            Promise.promise().complete(res);
        }, failure -> {
            Promise.promise().fail(failure);
        });
    }
}