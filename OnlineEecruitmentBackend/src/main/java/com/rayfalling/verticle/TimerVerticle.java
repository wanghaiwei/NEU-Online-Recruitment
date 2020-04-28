package com.Rayfalling.verticle;

import com.Rayfalling.Shared;
import io.reactivex.Single;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Handler;
import io.vertx.core.Promise;
import io.vertx.reactivex.core.eventbus.MessageConsumer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;

@SuppressWarnings("ResultOfMethodCallIgnored")
public class TimerVerticle extends AbstractVerticle {
    private static final ArrayList<Long> timers = new ArrayList<>();
    private final Logger logger = LogManager.getLogger("Timer");
    MessageConsumer<Handler<Long>> messageConsumer;
    
    @Override
    public void start(@NotNull Promise<Void> startPromise) {
        Single.just(true).flatMap(__ ->{
            messageConsumer = Shared.getVertx().eventBus().<Handler<Long>>consumer("register.timer").handler(msg -> {
                long timerId = Shared.getVertx().setTimer(config().getInteger("delay"), msg.body());
                timers.add(timerId);
            });
    
            messageConsumer.completionHandler(res -> {
                if (res.succeeded()) {
                    logger.info("Timer server handler register success");
                } else {
                    logger.error("Timer server handler registration failed!");
                }
            });
            return Single.just(messageConsumer);
        }).subscribe(res -> {
            startPromise.complete();
        }, startPromise::fail);
    }
    
    @Override
    public void stop(@NotNull Promise<Void> stopPromise) throws Exception {
        Single.just(timers).flatMap(timer -> {
            timer.forEach(timerId -> {
                Shared.getVertx().cancelTimer(timerId);
            });
            return Single.just(timer);
        }).doOnSubscribe(res -> {
            logger.info("Starting closing Timer Verticle...");
        }).doOnSuccess(res -> {
            logger.info("Timer Verticle closed succeed!");
        }).subscribe(res -> {
            stopPromise.complete();
        }, stopPromise::fail);
    }
}
