package com.Rayfalling.router.Group;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

/**
 * 圈子相关路由
 *
 * @author Rayfalling
 */
public class GroupRouter {
    private static Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "/api/group";
        
        router.mountSubRouter("/admin", GroupAdminRouter.getRouter());
        router.get("/").handler(GroupRouter::GroupIndex);
        
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }
    
    public static Router getRouter() {
        return router;
    }
    
    private static void GroupIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of group router.").trim());
    }
}
