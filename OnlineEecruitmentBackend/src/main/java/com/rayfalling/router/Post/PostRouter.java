package com.Rayfalling.router.Post;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

/**
 * 动态相关路由
 *
 * @author Rayfalling
 */
public class PostRouter {
    private static Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "/api/post";
        
        router.get("/").handler(PostRouter::PostIndex);
        
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }
    
    public static Router getRouter() {
        return router;
    }
    
    private static void PostIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of post router.").trim());
    }
}
