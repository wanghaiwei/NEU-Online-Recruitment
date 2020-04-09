package com.Rayfalling.router;

import com.Rayfalling.Shared;
import com.Rayfalling.config.MainRouterConfig;
import com.Rayfalling.router.Admin.AdminRouter;
import com.Rayfalling.router.Group.GroupRouter;
import com.Rayfalling.router.Post.PostRouter;
import com.Rayfalling.router.Postion.PositionRouter;
import com.Rayfalling.router.User.UserRouter;
import io.vertx.core.http.HttpMethod;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import io.vertx.reactivex.ext.web.handler.BodyHandler;
import io.vertx.reactivex.ext.web.handler.CorsHandler;
import org.jetbrains.annotations.NotNull;

public class MainRouter {
    
    private static Router router;
    private static MainRouter instance = new MainRouter();
    
    //让构造函数为 private，这样该类就不会被实例化
    private MainRouter() {
        router = Router.router(Shared.getVertx());
        router.route().handler(CorsHandler.create("*")
                                          .allowedMethod(HttpMethod.GET)
                                          .allowedMethod(HttpMethod.POST)
                                          .allowedHeader("*")
                                          .allowedHeader("content-type"));
        //创建bodyHandler
        router.route().handler(BodyHandler.create());
        //依据配置开始路由记录
        if (MainRouterConfig.getInstance().getLogRequests()) {
            router.route().handler(
                    router -> {
                        Shared.getRouterLogger().info(router.normalisedPath());
                        router.next();
                    });
        }
        
        //mount subRouters
        Router subRouter = Router.router(Shared.getVertx());
        subRouter.get("/").handler(this::pageMainIndex);
        
        //挂载用户相关url
        subRouter.mountSubRouter("/user", UserRouter.getInstance().getRouter());
        subRouter.mountSubRouter("/position", PositionRouter.getInstance().getRouter());
        subRouter.mountSubRouter("/post", PostRouter.getInstance().getRouter());
        subRouter.mountSubRouter("/group", GroupRouter.getInstance().getRouter());
        subRouter.mountSubRouter("/admin", AdminRouter.getInstance().getRouter());
        
        //挂载主路由
        router.mountSubRouter("/api", subRouter);
    }
    
    //获取唯一可用的对象
    public static MainRouter getInstance() {
        return instance;
    }
    
    public Router getRouter() {
        return router;
    }
    
    
    private void pageMainIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of api router.").trim());
    }
}
