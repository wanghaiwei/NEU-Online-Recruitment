package com.Rayfalling.router.Post;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;

/**
 * 动态相关路由
 * @author rayfalling
 * */
public class PostRouter {
    private static Router router;
    private static PostRouter instance = new PostRouter();

    //让构造函数为 private，这样该类就不会被实例化
    private PostRouter() {
        router = Router.router(Shared.getVertx());
        router.get("/").handler(this::PostIndex);
    }

    //获取唯一可用的对象
    public static PostRouter getInstance() {
        return instance;
    }

    public Router getRouter() {
        return router;
    }

    private void PostIndex(RoutingContext context) {
        context.response().end(("This is the index page of post router.").trim());
    }
}
