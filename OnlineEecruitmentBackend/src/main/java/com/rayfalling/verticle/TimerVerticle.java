package com.Rayfalling.verticle;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.data.TimerEvent;
import io.reactivex.Single;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Handler;
import io.vertx.core.Promise;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.core.eventbus.MessageConsumer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;

@SuppressWarnings("ResultOfMethodCallIgnored")
public class TimerVerticle extends AbstractVerticle {
    private static final ArrayList<Long> timers = new ArrayList<>();
    private static Long delay = 0L;
    private final Logger logger = LogManager.getLogger("Timer");
    
    public synchronized static Single<Boolean> register(TimerEvent event) {
        return Single.just(event).flatMap(e -> {
            long timerId = Shared.getVertx().setTimer(delay, id -> event.event());
            timers.add(timerId);
            return Single.just(true);
        }).onErrorReturnItem(false);
    }
    
    @Override
    public void start(@NotNull Promise<Void> startPromise) {
        Single.just(true).flatMap(__ -> {
            delay = config().getLong("delay");
            return Single.just(true);
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
