package com.Rayfalling.router.Postion;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

/**
 * 职位相关路由
 *
 * @author rayfalling
 */
public class PositionRouter {
    private static Router router = Router.router(Shared.getVertx());
    
    public static Router getRouter() {
        return router;
    }
    
    //让构造函数为 private，这样该类就不会被实例化
    static {
        String prefix = "/api/position";
        
        router.get("/").handler(PositionRouter::PositionIndex);
        
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }
    
    private static void PositionIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of position router.").trim());
    }
}
