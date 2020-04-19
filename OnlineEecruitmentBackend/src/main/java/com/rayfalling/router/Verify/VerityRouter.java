package com.Rayfalling.router.Verify;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.Utils.Common;
import com.Rayfalling.middleware.data.VerifyCode;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

/**
 * 用户相关路由
 *
 * @author Rayfalling
 */
public class VerityRouter {
    private static final Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "/api/verify";
        
        router.get("/").handler(VerityRouter::UserIndex);
        router.post("/phone/new").handler(VerityRouter::VerifyPhone);
        router.post("/mail/new").handler(VerityRouter::VerifyMail);
        
        for (Route route : router.getRoutes()) {
            if (route.getPath() != null) {
                Shared.getRouterLogger().info(prefix + route.getPath() + " mounted succeed");
            }
        }
    }
    
    public static Router getRouter() {
        return router;
    }
    
    private static void UserIndex(@NotNull RoutingContext context) {
        context.response().end(("This is the index page of verify router.").trim());
    }
    
    /**
     * 短信发送路由
     * */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void VerifyPhone(@NotNull RoutingContext context) {
        Single.just(context).map(res -> res.getBody().toJsonObject()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).map(params -> {
            //check param is null
            String phone = params.getString("phone", "");
            
            if (Common.isNotMobile(phone)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            return new JsonObject().put("phone", phone);
        }).flatMap(params -> {
            Shared.getVertx().eventBus().<JsonObject>request("verify.phone", params, result -> {
                if (result.succeeded()) {
                    if (result.result().body().getString("Code").equals("OK")) {
                        JsonResponse.RespondPreset(context, PresetMessage.SUCCESS);
                        context.session().put("Code", VerifyCode.getInstance().find(params.getString("phone")));
                    } else {
                        JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                        Shared.getRouterLogger()
                              .error(context.normalisedPath() + " " + result.cause().getMessage());
                    }
                } else {
                    JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                    Shared.getRouterLogger()
                          .error(context.normalisedPath() + " " + result.result().body().getString("Message"));
                }
            });
            
            return Single.just(params);
        }).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    
    /**
     * 邮箱验证发送路由
     * */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void VerifyMail(@NotNull RoutingContext context) {
        Single.just(context).map(res -> res.getBody().toJsonObject()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).map(params -> {
            //check mail is null
            String mail = params.getString("mail", "");
            
            if (Common.isNotEmail(mail)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            return new JsonObject().put("mail_to", mail);
        }).flatMap(params -> {
            Shared.getVertx().eventBus().<JsonObject>request("verify.mail", params, result -> {
                if (result.succeeded()) {
                    if (result.result().body().getBoolean("status")) {
                        JsonResponse.RespondPreset(context, PresetMessage.SUCCESS);
                        context.session().put("Code", VerifyCode.getInstance().find(params.getString("mail")));
                    } else {
                        JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                        Shared.getRouterLogger()
                              .error(context.normalisedPath() + " " + result.cause().getMessage());
                    }
                } else {
                    JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                    Shared.getRouterLogger()
                          .error(context.normalisedPath() + " " + result.result().body().getString("Message"));
                }
            });
            
            return Single.just(params);
        }).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
