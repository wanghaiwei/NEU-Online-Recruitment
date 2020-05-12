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
        router.post("/all")
              .handler(PostRouter::FetchAll);
        
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
        router.post("/comment/new")
              .handler(AuthRouter::AuthToken)
              .handler(AuthRouter::AuthIsBanned)
              .handler(PostRouter::PostComment);
        router.post("/comment/list")
              .handler(AuthRouter::AuthToken)
              .handler(PostRouter::AllComment);
        router.post("/favorite")
              .handler(AuthRouter::AuthToken)
              .handler(PostRouter::PostFavorite);
        router.post("/update")
              .handler(AuthRouter::AuthToken)
              .handler(PostRouter::PostUpdate);
        router.post("/comment/reply")
              .handler(AuthRouter::AuthToken)
              .handler(AuthRouter::AuthIsBanned)
              .handler(PostRouter::PostCommentReply);
        router.post("/comment/reply/list")
              .handler(AuthRouter::AuthToken)
              .handler(AuthRouter::AuthIsBanned)
              .handler(PostRouter::AllReply);
        
        /* 未实现 */
        router.post("/report")
              .handler(AuthRouter::AuthToken)
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
     * 获取动态路由
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
        }).flatMap(PostHandler::DatabaseFetchAllPost).doOnError(err -> {
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
     * 获取动态评论路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void AllComment(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            return Single.just(new JsonObject().put("post_id", param.getInteger("post_id")));
        }).flatMap(PostHandler::DatabaseFetchAllComment).doOnError(err -> {
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
    
    /* TODO */
    /**
     * 获取动态评论路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void AllReply(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            return Single.just(new JsonObject().put("comment_id", param.getInteger("comment_id")));
        }).flatMap(PostHandler::DatabaseFetchAllComment).doOnError(err -> {
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
     * 动态收藏路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PostFavorite(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(param.put("post_id", param.getInteger("post_id")).put("user_id", token.getId()));
        }).flatMap(PostHandler::DatabaseFavoritePost).doOnError(err -> {
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
            JsonResponse.RespondSuccess(context, "Favorite post id: " + result + " success");
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
    
    /**
     * 动态更新路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PostUpdate(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(param.put("user_id", token.getId()));
        }).flatMap(PostHandler::DatabaseUpdatePost).doOnError(err -> {
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
    
    /* TODO */
    /**
     * 动态评论回复路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void PostCommentReply(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(param -> {
            Token token = context.session().get("token");
            return Single.just(param.put("user_id", token.getId()));
        }).flatMap(PostHandler::DatabasePostCommentReply).doOnError(err -> {
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
            JsonResponse.RespondSuccess(context, "Reply comment id: " + result + " success");
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
