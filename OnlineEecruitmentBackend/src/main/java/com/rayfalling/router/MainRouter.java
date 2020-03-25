package com.rayfalling.router;

import com.rayfalling.Shared;
import io.vertx.core.Vertx;
import io.vertx.core.http.HttpMethod;
import io.vertx.rxjava.ext.web.Router;
import io.vertx.rxjava.ext.web.handler.CorsHandler;

public class MainRouter {

    private static Router router;
    private static MainRouter instance = new MainRouter();
    private static Vertx vertx;

    //让构造函数为 private，这样该类就不会被实例化
    private MainRouter() {
        router = Router.router(Shared.getInstance().getVertx());
        router.route().handler(CorsHandler.create("*")
                .allowedMethod(HttpMethod.GET)
                .allowedMethod(HttpMethod.POST)
                .allowedHeader("*")
                .allowedHeader("content-type"));
    }

    //获取唯一可用的对象
    public static MainRouter getInstance() {
        return instance;
    }

    public Router getRouter(){
        return router;
    }
}
