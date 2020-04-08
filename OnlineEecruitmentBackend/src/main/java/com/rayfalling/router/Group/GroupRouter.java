package com.Rayfalling.router.Group;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;

/**
 * 圈子相关路由
 * @author rayfalling
 */
public class GroupRouter {
    private static Router router;
    private static GroupRouter instance = new GroupRouter();

    //让构造函数为 private，这样该类就不会被实例化
    private GroupRouter() {
        router = Router.router(Shared.getVertx());
        router.mountSubRouter("/admin", GroupAdminRouter.getInstance().getRouter());
        router.get("/").handler(this::GroupIndex);
    }

    //获取唯一可用的对象
    public static GroupRouter getInstance() {
        return instance;
    }

    public Router getRouter() {
        return router;
    }

    private void GroupIndex(RoutingContext context) {
        context.response().end(("This is the index page of group router.").trim());
    }
}
