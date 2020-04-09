package com.Rayfalling.router.Group;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

/**
 * 圈子管理相关路由
 * @author rayfalling
 * */
public class GroupAdminRouter {
    private static Router router = Router.router(Shared.getVertx());
    
    public static Router getRouter() {
        return router;
    }
    
    //静态初始化块
    static {
        String prefix = "/api/group/admin";
    
        router.get("/").handler(GroupAdminRouter::GroupIndex);
    
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }

    private static void GroupIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of group admin router.").trim());
    }
}
