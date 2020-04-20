package com.Rayfalling.router.Postion;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.position.PositionHandler;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.router.User.AuthRouter;
import io.reactivex.Single;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

/**
 * 职位相关路由
 *
 * @author Rayfalling
 */
public class PositionRouter {
    private static final Router router = Router.router(Shared.getVertx());
    
    //让构造函数为 private，这样该类就不会被实例化
    static {
        String prefix = "/api/position";
        
        router.get("/").handler(PositionRouter::PositionIndex);
        
        /* 不需要鉴权的路由 */
        router.get("/category/all").handler(PositionRouter::PositionCategoryAll);
        router.post("/search").handler(PositionRouter::PositionCategoryAll);
        
        /* 需要鉴权的路由 */
        router.post("/post").handler(AuthRouter::AuthToken).handler(PositionRouter::PositionPostNew);
        router.post("/delete").handler(AuthRouter::AuthToken).handler(PositionRouter::PositionCategoryAll);
        router.post("/favorite").handler(AuthRouter::AuthToken).handler(PositionRouter::PositionCategoryAll);
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }
    
    public static Router getRouter() {
        return router;
    }
    
    private static void PositionIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of position router.").trim());
    }
    
    /**
     * 获取职位类别路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PositionCategoryAll(@NotNull RoutingContext context) {
        Single.just(context).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).flatMap(param -> PositionHandler.DatabaseQueryPositionCategory()).doOnError(err -> {
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
     * 发布职位路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PositionPostNew(@NotNull RoutingContext context) {
        Single.just(context).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).flatMap(param -> PositionHandler.DatabaseQueryPositionCategory()).doOnError(err -> {
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
}
