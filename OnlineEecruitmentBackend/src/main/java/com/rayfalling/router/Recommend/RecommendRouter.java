package com.Rayfalling.router.Recommend;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Recommend.RecommendHandler;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.Utils.Common;
import com.Rayfalling.middleware.data.VerifyCode;
import com.Rayfalling.router.User.AuthRouter;
import com.Rayfalling.router.Verify.VerityRouter;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

import static com.Rayfalling.router.MainRouter.getJsonObjectSingle;

public class RecommendRouter {
    private static final Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "/api/verify";
        
        router.get("/")
              .handler(AuthRouter::AuthToken)
              .handler(RecommendRouter::RecommendIndex);
        router.post("/list")
//              .handler(AuthRouter::AuthToken)
              .handler(RecommendRouter::RecommendList);
        router.post("/record")
              .handler(AuthRouter::AuthToken)
              .handler(RecommendRouter::RecommendRecord);
        
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }
    
    public static Router getRouter() {
        return router;
    }
    
    private static void RecommendIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of recommend router.").trim());
    }
    
    /**
     * 推荐路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void RecommendList(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(params -> {
            return Single.just(params);
        }).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_UNKNOWN.toString());
            }
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 推荐反馈路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void RecommendRecord(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(params -> {
            
            return Single.just(params);
        }).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_UNKNOWN.toString());
            }
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
