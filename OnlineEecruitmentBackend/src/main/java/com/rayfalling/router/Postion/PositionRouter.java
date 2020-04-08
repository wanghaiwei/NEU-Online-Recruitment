package com.Rayfalling.router.Postion;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;

/**
 * 职位相关路由
 * @author rayfalling
 * */
public class PositionRouter {
    private static Router router;
    private static PositionRouter instance = new PositionRouter();

    //让构造函数为 private，这样该类就不会被实例化
    private PositionRouter() {
        router = Router.router(Shared.getVertx());
        router.get("/").handler(this::PositionIndex);
    }

    //获取唯一可用的对象
    public static PositionRouter getInstance() {
        return instance;
    }

    public Router getRouter() {
        return router;
    }

    private void PositionIndex(RoutingContext context) {
        context.response().end(("This is the index page of position router.").trim());
    }
}
