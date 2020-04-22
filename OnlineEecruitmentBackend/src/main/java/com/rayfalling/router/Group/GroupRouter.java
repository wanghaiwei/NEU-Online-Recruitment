package com.Rayfalling.router.Group;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Group.GroupHandler;
import com.Rayfalling.handler.Position.PositionHandler;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.router.User.AuthRouter;
import io.reactivex.Single;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

import static com.Rayfalling.router.MainRouter.getJsonObjectSingle;

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
        
        /* 不需要鉴权的路由 */
        router.get("/search").handler(GroupRouter::GroupCategoryAll);
        router.get("/category/all").handler(GroupRouter::GroupCategoryAll);
        
        /* 需要鉴权的路由 */
        router.post("/create").handler(AuthRouter::AuthToken).handler(GroupRouter::GroupCreate);
        router.post("/delete").handler(AuthRouter::AuthToken).handler(GroupRouter::GroupCreate);
        router.post("/favorite").handler(AuthRouter::AuthToken).handler(GroupRouter::GroupCreate);
        
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
    
    /**
     * 获取职位类别路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void GroupCategoryAll(@NotNull RoutingContext context) {
        Single.just(context).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).flatMap(param -> GroupHandler.DatabaseQueryGroupCategory()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
        }).doAfterSuccess(result -> {
            JsonResponse.RespondSuccess(context, result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 创建圈子路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void GroupCreate(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            param.put("user_id", token.getId());
            
            return Single.just(param);
        }).flatMap(GroupHandler::DatabaseNewGroup).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
        }).flatMap(result -> {
            if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            } else if (result == -2) {
                JsonResponse.RespondPreset(context, PresetMessage.OVER_MANAGE_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.OVER_MANAGE_ERROR.toString());
            } else if (result == -3) {
                JsonResponse.RespondPreset(context, PresetMessage.USER_NOT_MEET_CREATE_LIMIT_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.USER_NOT_MEET_CREATE_LIMIT_ERROR.toString());
            }
            
            JsonResponse.RespondSuccess(context, "Group created success");
            return Single.just(result);
        }).doAfterSuccess(result -> {
            JsonResponse.RespondSuccess(context, result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
