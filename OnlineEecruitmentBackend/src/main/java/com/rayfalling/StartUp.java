package com.rayfalling;


import com.rayfalling.config.DatabaseVerticleConfig;
import com.rayfalling.config.MainVerticleConfig;
import com.rayfalling.verticle.DatabaseVerticle;
import com.rayfalling.verticle.MainVerticle;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import rx.Single;

import java.util.List;
import java.util.Scanner;

public class StartUp {
    private static String MainVerticleDeploymentID;
    private static String DatabaseVerticleDeploymentID;

    public static void main(String[] args) {
        Logger logger = LogManager.getLogger("Startup");

        Single.just(Shared.getInstance()).map(shared -> {
            shared.getVertx()
                  .rxDeployVerticle(MainVerticle::new, MainVerticleConfig.getInstance())
                  .doOnError(err -> {
                      logger.error(err.getMessage());
                      logger.fatal("Failed to start MainVerticle instances.");
                  })
                  .doOnSuccess(res -> {
                      MainVerticleDeploymentID = res;
                      logger.info("MainVerticle instances startup succeeded. Now starting DatabaseVerticle...");
                  });

            return shared;
        }).map(shared -> {
            shared.getVertx()
                  .rxDeployVerticle(DatabaseVerticle::new, DatabaseVerticleConfig.getInstance())
                  .doOnError(err -> {
                      logger.error(err.getMessage());
                      logger.fatal("Failed to start DatabaseVerticle instances.");
                  })
                  .doOnSuccess(res -> {
                      DatabaseVerticleDeploymentID = res;
                      logger.info("DatabaseVerticle instances startup succeeded.");
                  });

            return shared;
        }).subscribe(res -> {
            logger.info("Startup operation finished successfully.");
        }, err -> {
            logger.error(err.getMessage());
            logger.fatal("Startup operation finished with error(s). Exiting server...");
            System.exit(-1);
        });

        Scanner sc = new Scanner(System.in);
        System.out.println(sc.nextLine());

        while (sc.hasNext()){
            String input  = sc.next();
            if(input.toLowerCase().equals("exit")){
                stop();
            }
        }

    }

    private static void stop() {
        Logger logger = LogManager.getLogger("Shutdown");

        Single.just(Shared.getInstance()).map(shared -> {
            shared.getVertx()
                  .undeploy(MainVerticleDeploymentID, res ->{
                      if(res.succeeded()){
                          logger.info("MainVerticle instances stop succeeded. Now stopping DatabaseVerticle...");
                      }else{
                          logger.fatal("Failed to stop MainVerticle instances.");
                      }
                  });

            return shared;
        }).map(shared -> {
            shared.getVertx()
                  .undeploy(DatabaseVerticleDeploymentID, res ->{
                      if(res.succeeded()){
                          logger.info("DatabaseVerticle instances stop succeeded.");
                      }else{
                          logger.fatal("Failed to stop DatabaseVerticle instances.");
                      }
                  });

            return shared;
        }).subscribe(res -> {
            logger.info("Stop operation finished successfully.");
        }, err -> {
            logger.error(err.getMessage());
            logger.fatal("Stop operation finished with error(s). Please check task manager and kill it manually...");
            System.exit(-1);
        });
    }
}
