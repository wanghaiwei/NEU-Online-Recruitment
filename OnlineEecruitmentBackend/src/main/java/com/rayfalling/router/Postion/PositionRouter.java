package com.Rayfalling.router.Postion;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Position.PositionHandler;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.router.User.AuthRouter;
import io.netty.util.internal.UnstableApi;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

import static com.Rayfalling.router.MainRouter.getJsonObjectSingle;

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
        
        router.get("/")
              .handler(PositionRouter::PositionIndex);
        
        /* 不需要鉴权的路由 */
        router.post("/search")
              .handler(PositionRouter::PositionSearch);
        router.get("/category/all")
              .handler(PositionRouter::PositionCategoryAll);
        
        /* 需要鉴权的路由 */
        router.post("/post")
              .handler(AuthRouter::AuthToken)
              .handler(AuthRouter::AuthQuota)
              .handler(PositionRouter::PositionPostNew);
        router.post("/delete")
              .handler(AuthRouter::AuthToken)
              .handler(PositionRouter::PositionPostDelete);
        router.post("/favorite")
              .handler(AuthRouter::AuthToken)
              .handler(PositionRouter::PositionFavorite);
        
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
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).flatMap(param -> PositionHandler.DatabaseQueryPositionCategory()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).doAfterSuccess(result -> {
            JsonResponse.RespondSuccess(context, result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    //TODO 完成相关推荐算法部分
    
    /**
     * 职位搜索路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    @UnstableApi
    private static void PositionSearch(@NotNull RoutingContext context) {
        Single.just(context).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).flatMap(param -> PositionHandler.DatabaseQueryPositionCategory()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
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
        getJsonObjectSingle(context).flatMap(param -> {
            Token sessionToken = context.session().get("token");
            if (param.getString("position_des").length() < 200) {
                JsonResponse.RespondPreset(context, PresetMessage.DESCRIPTION_LESS_200_LIMIT_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.DESCRIPTION_LESS_200_LIMIT_ERROR.toString());
            }
            return Single.just(param.put("user_id", sessionToken.getId()));
        }).flatMap(PositionHandler::DatabaseNewPosition).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_UNKNOWN.toString());
            }
        }).doAfterSuccess(result -> {
            if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.OUT_OF_POST_QUOTA_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.OUT_OF_POST_QUOTA_ERROR.toString());
            }
            JsonResponse.RespondSuccess(context, new JsonObject().put("post_id", result));
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 删除职位路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PositionPostDelete(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token sessionToken = context.session().get("token");
            if (param.getInteger("position_id") == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            return Single.just(param.put("user_id", sessionToken.getId()));
        }).flatMap(PositionHandler::DatabaseDeletePosition).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_UNKNOWN.toString());
            }
        }).doAfterSuccess(result -> {
            if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
            JsonResponse.RespondSuccess(context, "Delete Success");
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 收藏职位路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PositionFavorite(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token sessionToken = context.session().get("token");
            if (param.getInteger("pid") == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            return Single.just(param.put("user_id", sessionToken.getId()).put("position_id", param.getInteger("pid")));
        }).flatMap(PositionHandler::DatabaseFavourPosition).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_UNKNOWN.toString());
            }
        }).doAfterSuccess(result -> {
            if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
            JsonResponse.RespondSuccess(context, "Favour position Success");
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
