package com.Rayfalling.router.Post;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Post.PostHandler;
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
 * 动态相关路由
 *
 * @author Rayfalling
 */
@SuppressWarnings("DuplicatedCode")
public class PostRouter {
    private static final Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "/api/post";
        
        router.get("/")
              .handler(PostRouter::PostIndex);
        
        /* 不需要鉴权的路由 */
        router.get("/all")
              .handler(PostRouter::FetchAll);
        router.get("/category/all")
              .handler(MainRouter::UnImplementedRouter);
        
        /* 需要鉴权的路由 */
        router.post("/new")
              .handler(AuthRouter::AuthToken)
              .handler(AuthRouter::AuthIsBanned)
              .handler(PostRouter::PostNew);
        router.post("/like")
              .handler(AuthRouter::AuthToken)
              .handler(PostRouter::PostLike);
        router.post("/delete")
              .handler(AuthRouter::AuthToken)
              .handler(PostRouter::PostDelete);
        router.post("/comment")
              .handler(AuthRouter::AuthToken)
              .handler(AuthRouter::AuthIsBanned)
              .handler(PostRouter::PostComment);
    
        /* 未实现 */
        router.post("/report")
              .handler(AuthRouter::AuthToken)
              .handler(MainRouter::UnImplementedRouter);
        router.post("/update")
              .handler(AuthRouter::AuthToken)
              .handler(MainRouter::UnImplementedRouter);
        router.post("/favorite")
              .handler(AuthRouter::AuthToken)
              .handler(MainRouter::UnImplementedRouter);
        router.post("/comment/reply")
              .handler(AuthRouter::AuthToken)
              .handler(AuthRouter::AuthIsBanned)
              .handler(MainRouter::UnImplementedRouter);
        router.post("/comment/report")
              .handler(AuthRouter::AuthToken)
              .handler(MainRouter::UnImplementedRouter);
        router.post("/comment/reply/report")
              .handler(AuthRouter::AuthToken)
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
        context.response().end(("This is the index page of post router.").trim());
    }
    
    /**
     * 创建圈子路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void FetchAll(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            if (!param.getString("sort_col").equals("hottest") && !param.getString("sort_col").equals("newest")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            
            return Single.just(new JsonObject().put("group_id", param.getInteger("group_id"))
                                               .put("sort_col", param.getString("sort_col")));
        }).flatMap(PostHandler::DatabaseFetchAll).doOnError(err -> {
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
     * 发布动态路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PostNew(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(param.put("user_id", token.getId()));
        }).flatMap(PostHandler::DatabaseNewPost).doOnError(err -> {
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
            JsonResponse.RespondSuccess(context, "Post new id: " + result + " success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 删除动态路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PostDelete(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(param.put("user_id", token.getId()));
        }).flatMap(PostHandler::DatabaseDeletePost).doOnError(err -> {
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
            JsonResponse.RespondSuccess(context, "Delete post id: " + result + " success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 动态点赞路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PostLike(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(param.put("user_id", token.getId()));
        }).flatMap(PostHandler::DatabaseLikePost).doOnError(err -> {
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
            JsonResponse.RespondSuccess(context, "Like post id: " + result + " success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 动态评论路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PostComment(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(param.put("user_id", token.getId()));
        }).flatMap(PostHandler::DatabasePostComment).doOnError(err -> {
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
            JsonResponse.RespondSuccess(context, "Comment id: " + result + " success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
