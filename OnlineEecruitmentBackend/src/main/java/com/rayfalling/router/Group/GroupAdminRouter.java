package com.Rayfalling.router.Group;

import com.Rayfalling.Shared;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;

/**
 * 圈子管理相关路由
 * @author rayfalling
 * */
public class GroupAdminRouter {
    private static Router router;
    private static GroupAdminRouter instance = new GroupAdminRouter();

    //让构造函数为 private，这样该类就不会被实例化
    private GroupAdminRouter() {
        router = Router.router(Shared.getInstance().getVertx());
        router.get("/").handler(this::GroupIndex);
    }

    //获取唯一可用的对象
    public static GroupAdminRouter getInstance() {
        return instance;
    }

    public Router getRouter() {
        return router;
    }

    private void GroupIndex(RoutingContext context) {
        context.response().end(("This is the index page of group admin router.").trim());
    }
}
