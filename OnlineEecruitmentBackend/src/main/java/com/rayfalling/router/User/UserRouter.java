package com.Rayfalling.router.User;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Auth.Authentication;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.Utils.Security.EncryptUtils;
import com.Rayfalling.middleware.Utils.Common;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.middleware.data.TokenStorage;
import com.Rayfalling.middleware.data.VerifyCode;
import com.Rayfalling.router.MainRouter;
import com.Rayfalling.router.UploadRouter;
import io.reactiverse.pgclient.Tuple;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.core.http.Cookie;
import io.vertx.reactivex.ext.web.*;
import org.jetbrains.annotations.NotNull;

import java.util.Set;

/**
 * 用户相关路由
 *
 * @author Rayfalling
 */
public class UserRouter {
    private static final Router router = Router.router(Shared.getVertx());
    
    //静态初始化块
    static {
        String prefix = "/api/user";
        
        router.get("/").handler(UserRouter::UserIndex);
        
        /* 不需要鉴权的路由 */
        router.post("/register").handler(UserRouter::UserRegister);
        router.post("/login").handler(UserRouter::UserLogin);
        router.post("/logout").handler(UserRouter::UserLogout);
        router.post("/password/reset").handler(UserRouter::UserLogout);
        
        /* 需要鉴权的路由 */
        router.post("/info/update").handler(AuthRouter::AuthToken).handler(UserRouter::UserInfoUpdate);
        router.post("/password/update").handler(AuthRouter::AuthToken).handler(UserRouter::UserLogout);
        router.post("/authentication").handler(AuthRouter::AuthToken).handler(UserRouter::UserLogout);
        
        /* 未实现的路由节点 */
        router.post("/follow").handler(MainRouter::UnImplementedRouter);
        router.post("/report").handler(MainRouter::UnImplementedRouter);
        
        
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
        context.response().end(("This is the index page of user router.").trim());
    }
    
    /**
     * 用户注册路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void UserRegister(@NotNull RoutingContext context) {
        Single.just(context).map(res -> res.getBody().toJsonObject()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).map(params -> {
            //check param is null
            String phone = params.getString("phone", "");
            String password = params.getString("password", "");
            
            if (password.equals("") || phone.equals("")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            
            if (Common.isNotMobile(phone)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            return new JsonObject().put("phone", phone).put("password", password);
        }).flatMap(params -> Authentication.DatabaseRegister(params).map(result -> {
            if (result == 0) {
                JsonResponse.RespondPreset(context, PresetMessage.SUCCESS);
            } else if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_REGISTERED_ERROR);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.PHONE_REGISTERED_ERROR.toString());
            } else if (result == -2) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger().error(context.normalisedPath() + " " + PresetMessage.ERROR_UNKNOWN.toString());
            }
            
            return result;
        })).doOnError(err -> {
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
     * 用户登录路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void UserLogin(@NotNull RoutingContext context) {
        Single.just(context).map(res -> res.getBody().toJsonObject()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).map(params -> {
            //check param is null
            String type = params.getString("type", "password");
            
            if (type.equals("")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            
            String phone = params.getString("phone", "");
            
            if (Common.isNotMobile(phone)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            if (type.equals("password")) {
                String password = params.getString("password", "");
                if (password.equals("")) {
                    JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                    Shared.getRouterLogger()
                          .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
                }
                return new JsonObject().put("phone", phone).put("password", password);
            } else if (type.equals("code")) {
                String VerifyCode = params.getString("code", "");
                if (VerifyCode.equals("")) {
                    JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                    Shared.getRouterLogger()
                          .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
                }
                return new JsonObject().put("phone", phone).put("VerifyCode", VerifyCode);
            }
            
            //default return
            return new JsonObject();
        }).flatMap(param -> {
            String phone = param.getString("phone");
            
            Session session = context.session();
            
            final Integer user_id = 0;
            if (session.data().containsKey("Code")) {
                VerifyCode.Code code = session.get("Code");
                VerifyCode.Code storageCode = VerifyCode.getInstance().find(phone);
                //防止劫持
                if (storageCode.equals(code)) {
                    if (code.isExpired()) {
                        JsonResponse.RespondFailure(context, 40001, "Verify code is expired");
                        Shared.getRouterLogger().warn(context.normalisedPath() + " Verify code is expired");
                    }
                    if (!code.getCode().equals(param.getString("VerifyCode", ""))) {
                        JsonResponse.RespondFailure(context, 40001, "Verify code incorrect");
                        Shared.getRouterLogger().warn(context.normalisedPath() + " Verify code incorrect");
                    }
                    return Authentication.DatabaseSelectId(phone).map(result -> {
                        if (result == -1) {
                            return -1;
                        }
                        return Tuple.of(result, phone);
                    });
                } else {
                    JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                    Shared.getRouterLogger().warn(context.normalisedPath() + PresetMessage.ERROR_UNKNOWN.toString());
                }
            } else {
                return Authentication.DatabaseLogin(param).map(result -> {
                    if (result == -1) {
                        return -1;
                    }
                    return Tuple.of(result, phone);
                    
                });
            }
            return Single.just(Tuple.of(0, phone));
        }).flatMap(param -> {
            Tuple token_param = (Tuple) param;
            if (token_param.getInteger(0) == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_UNREGISTER_ERROR);
                Shared.getRouterLogger().warn(context.normalisedPath() + PresetMessage.PHONE_UNREGISTER_ERROR);
            }
            Token token = new Token(token_param.getInteger(0), token_param.getString(1));
            TokenStorage.add(token);
            context.session().put("token", token);
            context.addCookie(Cookie.cookie("token", EncryptUtils.EncryptFromToken(token)));
            JsonResponse.RespondSuccess(context, "Login successful");
            Shared.getRouterLogger()
                  .info(context.normalisedPath() + " " + token_param.getString(1) + " Login");
            return Single.just(token);
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
     * 用户登出路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void UserLogout(@NotNull RoutingContext context) {
        Single.just(context).map(res -> res.getBody().toJsonObject()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).flatMap(params -> {
            Token token = context.session().get("token");
            token.setExpired();
            
            TokenStorage.remove(token.getUsername());
            
            context.session().remove("token");
            context.removeCookie("token");
            
            JsonResponse.RespondSuccess(context, "Logout success.");
            Shared.getRouterLogger().info("User " + token.getUsername() + " Logout");
            
            return Single.just(token);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 用户修改信息路由
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    private static void UserInfoUpdate(@NotNull RoutingContext context) {
        Single.just(context).map(res -> res.getBody().toJsonObject()).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
                Shared.getRouterLogger()
                      .error(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON.toString());
            }
        }).map(params -> {
            String username = ((Token) context.session().get("token")).getUsername();
            
            String user_description = params.getString("user_description", "");
            String nickname = params.getString("nickname", "");
            String gender = params.getString("gender", "");
            String user_avatar = params.getString("user_avatar", "");
            String expected_career_id = params.getString("expected_career", "");
            String identity = params.getString("identity", "");
            
            return Tuple.of(username, nickname, user_description, gender, user_avatar);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
