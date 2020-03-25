package com.rayfalling;


import com.rayfalling.verticle.MainVerticle;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class StartUp {
    public static void main(String[] args) {
        String verticlePackage = "com.rayfalling.verticle";
        Logger logger = LogManager.getLogger("Startup");
        MainVerticle mainVerticle = new MainVerticle();
        Shared.getInstance().getVertx().rxDeployVerticle(mainVerticle).doOnError(err -> {
            logger.fatal("Failed to start MainVerticle instances.");
        }).doOnSuccess(res -> {
            logger.info("MainVerticle instances startup succeeded. Now starting DatabaseVerticle...");
        }).subscribe(res -> {
            logger.info("Startup operation finished successfully.");
        }, err -> {
            logger.fatal("Startup operation finished with error(s). Exiting server...");
            System.exit(-1);
        });
    }
}
