package com.Rayfalling;


import com.Rayfalling.config.DatabaseVerticleConfig;
import com.Rayfalling.config.MainVerticleConfig;
import com.Rayfalling.middleware.Utils.Utils;
import com.Rayfalling.verticle.DatabaseVerticle;
import com.Rayfalling.verticle.MainVerticle;
import io.reactivex.Single;

import io.vertx.reactivex.core.Vertx;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.core.config.ConfigurationSource;
import org.apache.logging.log4j.core.config.Configurator;

import java.util.Scanner;


@SuppressWarnings("ResultOfMethodCallIgnored")
public class StartUp {
    private static String MainVerticleDeploymentID;
    private static String DatabaseVerticleDeploymentID;
    
    
    public static void main(String[] args) {
        //load log4j2 config
        try {
            ConfigurationSource source;
            source = new ConfigurationSource(Utils.LoadResource("log4j2.xml"));
            Configurator.initialize(ClassLoader.getSystemClassLoader(), source);
        } catch (Exception e) {
            Shared.getLogger().fatal(e.getMessage());
            e.printStackTrace();
        }
        
        final Logger logger = LogManager.getLogger("StartUp");
        
        Single.just(Vertx.vertx()).flatMap(resource -> {
            Shared.getVertx()
                  .rxDeployVerticle(MainVerticle::new, MainVerticleConfig.getInstance())
                  .doOnSuccess(res -> {
                      MainVerticleDeploymentID = res;
                      logger.info("MainVerticle instances startup succeeded.");
                  })
                  .doOnSubscribe(disposable -> logger.info("Starting MainVerticle..."))
                  .doOnError(err -> {
                      logger.error(err.getMessage());
                      logger.fatal("Failed to start MainVerticle instances.");
                      err.printStackTrace();
                  })
                  .subscribe(res -> {
                
                  }, failure -> {
                
                  });
            
            return Single.just(resource);
        }).flatMap(resource -> {
            Shared.getVertx()
                  .rxDeployVerticle(DatabaseVerticle::new, DatabaseVerticleConfig.getInstance())
                  .doOnError(err -> {
                      logger.error(err.getMessage());
                      logger.fatal("Failed to start DatabaseVerticle instances.");
                      err.printStackTrace();
                  })
                  .doOnSubscribe(disposable -> logger.info("Starting DatabaseVerticle..."))
                  .doOnSuccess(res -> {
                      DatabaseVerticleDeploymentID = res;
                      logger.info("DatabaseVerticle instances startup succeeded.");
                  })
                  .subscribe(res -> {
                
                  }, failure -> {
                
                  });
            
            return Single.just(resource);
        }).subscribe(res -> {
            logger.info("Rsync Startup operation finished successfully. Waiting for Verticle starting...");
        }, err -> {
            logger.error(err.getMessage());
            logger.fatal("Startup operation finished with error(s). Exiting server...");
            System.exit(-1);
        });
        
        //启动接收器等待退出信号
        Runnable thread = () -> {
            Scanner sc = new Scanner(System.in);
            
            while (sc.hasNext()) {
                String input = sc.next();
                if (input.toLowerCase().equals("exit")) {
                    stop();
                    System.exit(0);
                }
            }
        };
        thread.run();
    }
    
    private static void stop() {
        Logger logger = LogManager.getLogger("Shutdown");
        
        Single.just(Shared.getVertx()).map(shared -> {
            shared.undeploy(MainVerticleDeploymentID, res -> {
                if (res.succeeded()) {
                    logger.info("MainVerticle instances stop succeeded. Now stopping DatabaseVerticle...");
                } else {
                    logger.fatal("Failed to stop MainVerticle instances.");
                    logger.fatal(res.cause());
                }
            });
            
            return shared;
        }).map(shared -> {
            shared.undeploy(DatabaseVerticleDeploymentID, res -> {
                if (res.succeeded()) {
                    logger.info("DatabaseVerticle instances stop succeeded.");
                } else {
                    logger.fatal("Failed to stop DatabaseVerticle instances.");
                    logger.fatal(res.cause());
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
