package com.rayfalling;


import com.rayfalling.config.MainVerticleConfig;
import com.rayfalling.verticle.MainVerticle;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class StartUp {
    public static void main(String[] args) throws Exception {
        Logger logger = LogManager.getLogger("Startup");
        Shared.getInstance()
              .getVertx()
              .rxDeployVerticle(MainVerticle::new, MainVerticleConfig.getInstance())
              .doOnError(err -> {
                  logger.error(err.getMessage());
                  logger.fatal("Failed to start MainVerticle instances.");
              })
              .doOnSuccess(res -> {
                  logger.info("MainVerticle instances startup succeeded. Now starting DatabaseVerticle...");
              })
              .subscribe(res -> {
                  logger.info("Startup operation finished successfully.");
              }, err -> {
                  logger.error(err.getMessage());
                  logger.fatal("Startup operation finished with error(s). Exiting server...");
                  System.exit(-1);
              });
    }
}
