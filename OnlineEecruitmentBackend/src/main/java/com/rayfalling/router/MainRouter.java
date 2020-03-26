package com.rayfalling.router;

import com.rayfalling.Shared;
import com.rayfalling.config.MainRouterConfig;
import io.vertx.core.Vertx;
import io.vertx.core.http.HttpMethod;
import io.vertx.rxjava.ext.web.Router;
import io.vertx.rxjava.ext.web.RoutingContext;
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

        //依据配置开始路由记录
        if (MainRouterConfig.getInstance().getLogRequests()) {
            router.route().handler(
                    router -> {
                        Shared.getInstance().getLogger().info(router.normalisedPath());
                        router.next();
                    });
        }

        //mount subRouters
        Router subRouter = Router.router(Shared.getInstance().getVertx());
        subRouter.get("/").handler(this::pageMainIndex);
        router.mountSubRouter("/api", subRouter);
    }

    //获取唯一可用的对象
    public static MainRouter getInstance() {
        return instance;
    }

    public Router getRouter() {
        return router;
    }


    private void pageMainIndex(RoutingContext context) {
        context.response().end(("This is the index page of main router.\n" +
                                "Normally you should not see this, unless you are the maintainer of the webservice.\n")
                .trim());
    }
}
