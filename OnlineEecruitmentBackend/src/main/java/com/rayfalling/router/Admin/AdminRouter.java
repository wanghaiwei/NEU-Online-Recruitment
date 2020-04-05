package com.Rayfalling.router.Admin;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;

/**
 * 管理员相关路由
 * @author rayfalling
 * */
public class AdminRouter {
    private static Router router;
    private static AdminRouter instance = new AdminRouter();

    //让构造函数为 private，这样该类就不会被实例化
    private AdminRouter() {
        router = Router.router(Shared.getInstance().getVertx());
        router.get("/").handler(this::PostIndex);
    }

    //获取唯一可用的对象
    public static AdminRouter getInstance() {
        return instance;
    }

    public Router getRouter() {
        return router;
    }

    private void PostIndex(RoutingContext context) {
        context.response().end(("This is the index page of admin router.").trim());
    }
}
