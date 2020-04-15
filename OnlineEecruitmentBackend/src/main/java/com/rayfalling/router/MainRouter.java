package com.Rayfalling.router;

import com.Rayfalling.Shared;
import com.Rayfalling.config.MainRouterConfig;
import com.Rayfalling.router.Admin.AdminRouter;
import com.Rayfalling.router.Group.GroupRouter;
import com.Rayfalling.router.Post.PostRouter;
import com.Rayfalling.router.Postion.PositionRouter;
import com.Rayfalling.router.User.UserRouter;
import com.Rayfalling.router.Verify.VerityRouter;
import io.vertx.core.http.HttpMethod;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import io.vertx.reactivex.ext.web.handler.BodyHandler;
import io.vertx.reactivex.ext.web.handler.CorsHandler;
import io.vertx.reactivex.ext.web.handler.SessionHandler;
import io.vertx.reactivex.ext.web.sstore.LocalSessionStore;
import org.jetbrains.annotations.NotNull;

public class MainRouter {
    
    private static final Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "";
        
        router.route().handler(CorsHandler.create("*")
                                          .allowedMethod(HttpMethod.GET)
                                          .allowedMethod(HttpMethod.POST)
                                          .allowedHeader("*")
                                          .allowedHeader("content-type"));
        //创建bodyHandler
        router.route().handler(BodyHandler.create());
        router.route().handler(SessionHandler.create(LocalSessionStore.create(Shared.getVertx())));
        
        //依据配置开始路由记录
        if (MainRouterConfig.getInstance().getLogRequests()) {
            router.route().handler(
                    router -> {
                        Shared.getRouterLogger().info("Hit " + router.normalisedPath());
                        router.next();
                    });
        }
        
        //mount subRouters
        Router subRouter = Router.router(Shared.getVertx());
        subRouter.get("/").handler(MainRouter::pageMainIndex);
        
        //挂载用户相关url
        subRouter.mountSubRouter("/user", UserRouter.getRouter());
        subRouter.mountSubRouter("/position", PositionRouter.getRouter());
        subRouter.mountSubRouter("/post", PostRouter.getRouter());
        subRouter.mountSubRouter("/group", GroupRouter.getRouter());
        subRouter.mountSubRouter("/admin", AdminRouter.getRouter());
        subRouter.mountSubRouter("/verify", VerityRouter.getRouter());
        
        //挂载主路由
        router.mountSubRouter("/api", subRouter);
        
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }
    
    public static Router getRouter() {
        return router;
    }
    
    private static void pageMainIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of api router.").trim());
    }
}
