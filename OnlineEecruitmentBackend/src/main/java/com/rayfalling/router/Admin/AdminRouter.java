package com.Rayfalling.router.Admin;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Admin.AdminHandler;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.router.MainRouter;
import com.Rayfalling.router.User.AuthRouter;
import io.reactivex.Single;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

import static com.Rayfalling.router.MainRouter.getJsonObjectSingle;

/**
 * 管理员相关路由
 *
 * @author Rayfalling
 */
@SuppressWarnings("DuplicatedCode")
public class AdminRouter {
    private static final Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "/api/admin";
        
        router.get("/")
              .handler(AdminRouter::PostIndex);
        
        /* 需要鉴权的路由 */
        router.post("/auth/list").handler(AuthRouter::AuthToken)
              .handler(AdminRouter::AdminAuthAdmin)
              .handler(AdminRouter::AdminAuthList);
        router.post("/auth/confirm").handler(AuthRouter::AuthToken)
              .handler(AdminRouter::AdminAuthAdmin)
              .handler(AdminRouter::AdminAuthConfirm);
        router.post("/user/list").handler(AuthRouter::AuthToken)
              .handler(AdminRouter::AdminAuthAdmin)
              .handler(AdminRouter::AdminUserList);
        router.post("/user/shield").handler(AuthRouter::AuthToken)
              .handler(AdminRouter::AdminAuthAdmin)
              .handler(AdminRouter::AdminUserBan);
        router.post("/post/top").handler(AuthRouter::AuthToken)
              .handler(AdminRouter::AdminAuthAdmin)
              .handler(AdminRouter::AdminPinPost);
        
        /* 未实现的路由 */
        router.post("/update").handler(AuthRouter::AuthToken)
              .handler(AdminRouter::AdminAuthAdmin)
              .handler(MainRouter::UnImplementedRouter);
        router.post("/post/delete").handler(AuthRouter::AuthToken)
              .handler(AdminRouter::AdminAuthAdmin)
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
    
    private static void PostIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of admin router.").trim());
    }
    
    /**
     * 校验管路员身份
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void AdminAuthAdmin(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(token.getIdentity().IsAdmin());
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
            Shared.getRouterLogger().info("Admin authed");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 查询身份认证用户路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void AdminAuthList(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(AdminHandler::DatabaseQueryAuth).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).flatMap(result -> {
            JsonResponse.RespondSuccess(context, result);
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 身份认证确认用户路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void AdminAuthConfirm(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(AdminHandler::DatabaseAdminConfirmAuth).doOnError(err -> {
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
            JsonResponse.RespondSuccess(context, "Confirmed auth success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 查询身份认证用户路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void AdminUserList(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(AdminHandler::DatabaseQueryUser).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).flatMap(result -> {
            JsonResponse.RespondSuccess(context, result);
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 查询身份认证用户路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void AdminUserBan(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(AdminHandler::DatabaseQueryUser).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_DATABASE);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_DATABASE.toString());
            }
        }).flatMap(result -> {
            JsonResponse.RespondSuccess(context, result);
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
    private static void AdminPinPost(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(AdminHandler::DatabaseAdminPinPost).doOnError(err -> {
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
