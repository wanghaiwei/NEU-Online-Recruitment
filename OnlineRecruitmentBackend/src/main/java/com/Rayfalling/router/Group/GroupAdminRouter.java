package com.Rayfalling.router.Group;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Group.GroupAdminHandler;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.router.MainRouter;
import com.Rayfalling.router.User.AuthRouter;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

import static com.Rayfalling.router.MainRouter.getJsonObjectSingle;

/**
 * 圈子管理相关路由
 *
 * @author Rayfalling
 */
@SuppressWarnings("DuplicatedCode")
public class GroupAdminRouter {
    private static final Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "/api/group/admin";
        
        router.get("/")
              .handler(GroupAdminRouter::GroupIndex);
        
        /* 需要鉴权的路由 */
        router.post("/delete").handler(AuthRouter::AuthToken)
              .handler(GroupAdminRouter::GroupAuthAdmin)
              .handler(GroupAdminRouter::GroupDelete);
        router.post("/user/warning").handler(AuthRouter::AuthToken)
              .handler(GroupAdminRouter::GroupAuthAdmin)
              .handler(GroupAdminRouter::GroupUserWarn);
        router.post("/shield").handler(AuthRouter::AuthToken)
              .handler(GroupAdminRouter::GroupAuthAdmin)
              .handler(GroupAdminRouter::GroupUserShield);
        router.post("/post/top").handler(AuthRouter::AuthToken)
              .handler(GroupAdminRouter::GroupAuthAdmin)
              .handler(GroupAdminRouter::GroupPinPost);
        
        /* 未实现的路由 */
        router.post("/update").handler(AuthRouter::AuthToken)
              .handler(GroupAdminRouter::GroupAuthAdmin)
              .handler(MainRouter::UnImplementedRouter);
        router.post("/post/delete").handler(AuthRouter::AuthToken)
              .handler(GroupAdminRouter::GroupAuthAdmin)
              .handler(MainRouter::UnImplementedRouter);
        
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
        context.response().end(("This is the index page of group admin router.").trim());
    }
    
    /**
     * 校验用户是否是圈主
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void GroupAuthAdmin(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            if (param.getInteger("group_id") == null) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
            return Single.just(new JsonObject().put("user_id", token.getId())
                                               .put("group_id", param.getInteger("group_id")));
        }).flatMap(GroupAdminHandler::DatabaseGroupAuthAdmin).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).map(result -> {
            if (result) {
                context.next();
            } else {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_AUTH_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_AUTH_FAILED.toString());
            }
            return result;
        }).subscribe(res -> {
            Shared.getRouterLogger().info("Group admin authed");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 删除圈子申请路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void GroupDelete(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(param.put("user_id", token.getId()));
        }).flatMap(GroupAdminHandler::DatabaseDeleteGroup).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).flatMap(result -> {
            if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
            JsonResponse.RespondSuccess(context, "Commit delete request id: " + result + " success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 警告用户路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void GroupUserWarn(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(GroupAdminHandler::DatabaseGroupWarnUser).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).flatMap(result -> {
            if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
            JsonResponse.RespondSuccess(context, "Warn user success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 拉黑用户路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void GroupUserShield(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(GroupAdminHandler::DatabaseGroupBanUser).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).flatMap(result -> {
            if (!result) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
            JsonResponse.RespondSuccess(context, "Banned user success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 置顶动态用户路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void GroupPinPost(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(GroupAdminHandler::DatabaseGroupPinPost).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).flatMap(result -> {
            if (!result) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
            JsonResponse.RespondSuccess(context, "Pinned post success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
