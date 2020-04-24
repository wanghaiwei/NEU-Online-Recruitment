package com.Rayfalling.router.User;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Auth.AuthenticationHandler;
import com.Rayfalling.handler.Auth.UserInfoHandler;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.Utils.Common;
import com.Rayfalling.middleware.Utils.Security.EncryptUtils;
import com.Rayfalling.middleware.data.Identity;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.middleware.data.TokenStorage;
import com.Rayfalling.router.MainRouter;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.core.http.Cookie;
import io.vertx.reactivex.ext.web.Route;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;
import org.jetbrains.annotations.NotNull;

import static com.Rayfalling.router.MainRouter.getJsonObjectSingle;

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
        router.post("/login").handler(UserRouter::UserLogin);
        router.post("/logout").handler(UserRouter::UserLogout);
        router.post("/profile").handler(UserRouter::UserProfile);
        router.post("/register").handler(UserRouter::UserRegister);
        router.post("/password/reset").handler(UserRouter::UserResetPWD);
        
        /* 需要鉴权的路由 */
        router.post("/info/update").handler(AuthRouter::AuthToken).handler(UserRouter::UserInfoUpdate);
        router.post("/password/update").handler(AuthRouter::AuthToken).handler(UserRouter::UserUpdatePWD);
        router.post("/authentication").handler(AuthRouter::AuthToken).handler(UserRouter::UserAuthentication);
        
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
    @SuppressWarnings(value = "ResultOfMethodCallIgnored")
    private static void UserRegister(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).map(params -> {
            //check param is null
            String phone = params.getString("phone", "");
            String password = params.getString("password", "");
            
            if (password.equals("") || phone.equals("")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            
            if (Common.isNotMobile(phone)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            return new JsonObject().put("phone", phone).put("password", password);
        }).flatMap(params -> AuthenticationHandler.DatabaseUserRegister(params).map(result -> {
            if (result == 0) {
                JsonResponse.RespondPreset(context, PresetMessage.SUCCESS);
            } else if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_REGISTERED_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.PHONE_REGISTERED_ERROR.toString());
            } else if (result == -2) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger().error(context.normalisedPath() + " " + PresetMessage.ERROR_UNKNOWN.toString());
            }
            
            return result;
        })).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
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
    @SuppressWarnings(value = "ResultOfMethodCallIgnored")
    private static void UserLogin(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).map(params -> {
            //check param is null
            String type = params.getString("type", "password");
            
            if (type.equals("")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            
            String phone = params.getString("phone", "");
            
            if (Common.isNotMobile(phone)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            if (type.equals("password")) {
                String password = params.getString("password", "");
                if (password.equals("")) {
                    JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                    Shared.getRouterLogger()
                          .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
                }
                return new JsonObject().put("phone", phone).put("password", password);
            } else if (type.equals("code")) {
                String VerifyCode = params.getString("code", "");
                if (VerifyCode.equals("")) {
                    JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                    Shared.getRouterLogger()
                          .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
                }
                return new JsonObject().put("phone", phone).put("VerifyCode", VerifyCode);
            }
            
            //default return
            return new JsonObject();
        }).flatMap(param -> AuthRouter.AuthCode(context, param)).flatMap(param -> {
            String phone = param.getString("phone");
            
            if (!param.getBoolean("result")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
            return context.session().data().containsKey("Code") ?
                           AuthenticationHandler.DatabaseUserId(phone).flatMap(result -> {
                               return Single.just(new JsonObject().put("id", result).put("phone", phone));
                           }) :
                           AuthenticationHandler.DatabaseUserLogin(param).flatMap(result -> {
                               return Single.just(new JsonObject().put("id", result).put("phone", phone));
                           });
            
        }).flatMap(param -> {
            if (param.getInteger("id") == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_UNREGISTER_ERROR);
                Shared.getRouterLogger().warn(context.normalisedPath() + PresetMessage.PHONE_UNREGISTER_ERROR);
            }
            
            return Single.just(param);
        }).flatMap(UserInfoHandler::DatabaseUserQueryIdentity).flatMap(param -> {
            if (!param.getBoolean("result")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger().warn(context.normalisedPath() + PresetMessage.ERROR_FAILED);
            }
            
            Identity identity = Identity.mapFromDatabase(param.getInteger("user_identity"), param.getInteger("auth_identity"));
            
            Token token = new Token(param.getInteger("id"), param.getString("phone"), identity);
            TokenStorage.add(token);
            context.session().put("token", token);
            context.addCookie(Cookie.cookie("token", EncryptUtils.EncryptFromToken(token)));
            JsonResponse.RespondSuccess(context, "Login successful");
            Shared.getRouterLogger()
                  .info(context.normalisedPath() + " " + param.getString("phone") + " Login");
            return Single.just(token);
        }).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
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
    @SuppressWarnings(value = "ResultOfMethodCallIgnored")
    private static void UserLogout(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(params -> {
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
     * 用户信息获取
     */
    @SuppressWarnings(value = "ResultOfMethodCallIgnored")
    private static void UserProfile(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).flatMap(params -> {
            return Single.just(new JsonObject().put("user_id", params.getInteger("user_id")));
        }).flatMap(UserInfoHandler::DatabaseUserProfile).flatMap(result -> {
            if (result == null) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            } else {
                JsonResponse.RespondSuccess(context, result);
                return Single.just(result);
            }
            return Single.just(new JsonObject());
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 用户修改信息路由
     */
    @SuppressWarnings(value = "ResultOfMethodCallIgnored")
    private static void UserInfoUpdate(@NotNull RoutingContext context) {
        getJsonObjectSingle(context)
                .map(params -> new JsonObject().put("username", ((Token) context.session().get("token")).getUsername())
                                               .put("user_description", params.getString("user_description", ""))
                                               .put("nickname", params.getString("nickname", ""))
                                               .put("gender", params.getString("gender", "男"))
                                               .put("user_avatar", params.getString("user_avatar", ""))
                                               .put("expected_career_id", params.getInteger("expected_career_id", 0)))
                .flatMap(UserInfoHandler::DatabaseUserInfoUpdate).doOnError(err -> {
            
        }).doAfterSuccess(res -> {
            if (res == 0) {
                JsonResponse.RespondSuccess(context, "Update Success");
            } else {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger().error(context.normalisedPath() + " " + PresetMessage.ERROR_UNKNOWN.toString());
            }
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 用户忘记密码路由
     */
    @SuppressWarnings(value = "ResultOfMethodCallIgnored")
    private static void UserResetPWD(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).map(params -> {
            String phone = params.getString("phone", "");
            
            if (Common.isNotMobile(phone)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            String VerifyCode = params.getString("verification_code", "");
            String newPassword = params.getString("pwd_new", "");
            if (VerifyCode.equals("")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            return new JsonObject().put("phone", phone)
                                   .put("VerifyCode", VerifyCode)
                                   .put("pwd_new", newPassword);
        }).flatMap(param -> AuthRouter.AuthCode(context, param)).flatMap(param -> {
            if (!param.getBoolean("result")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
            
            return Single.just(param);
        }).flatMap(AuthenticationHandler::DatabaseResetPwd).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
        }).flatMap(param -> {
            if (param == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_UNREGISTER_ERROR);
                Shared.getRouterLogger().warn(context.normalisedPath() + PresetMessage.PHONE_UNREGISTER_ERROR);
            } else {
                JsonResponse.RespondSuccess(context, "Password reset successful");
            }
            return Single.just(param);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 用户更新密码路由
     */
    @SuppressWarnings(value = "ResultOfMethodCallIgnored")
    private static void UserUpdatePWD(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).map(params -> {
            String phone = ((Token) context.session().get("token")).getUsername();
            
            if (Common.isNotMobile(phone)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            String oldPassword = params.getString("pwd_old", "");
            String newPassword = params.getString("pwd_new", "");
            return new JsonObject().put("phone", phone).put("pwd_old", oldPassword).put("pwd_new", newPassword);
        }).flatMap(AuthenticationHandler::DatabaseUpdatePwd).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
        }).flatMap(param -> {
            if (param == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.OLD_PASSWORD_INCORRECT_ERROR);
                Shared.getRouterLogger().warn(context.normalisedPath() + PresetMessage.OLD_PASSWORD_INCORRECT_ERROR);
            } else {
                JsonResponse.RespondSuccess(context, "Password updated successful");
            }
            return Single.just(param);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
    
    /**
     * 用户身份认证路由
     */
    @SuppressWarnings(value = "ResultOfMethodCallIgnored")
    private static void UserAuthentication(@NotNull RoutingContext context) {
        getJsonObjectSingle(context).map(params -> {
            String username = ((Token) context.session().get("token")).getUsername();
            
            if (Common.isNotMobile(username)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            String code = params.getString("code", "");
            boolean mail_can_verify = false;
            
            if (code.equals("")) {
                mail_can_verify = true;
            }
            
            return new JsonObject().put("username", username)
                                   .put("identity", params.getInteger("identity", 0))
                                   .put("company", params.getString("company", ""))
                                   .put("position", params.getString("position", ""))
                                   .put("mail", params.getString("mail", ""))
                                   .put("VerifyCode", code)
                                   .put("mail_can_verify", mail_can_verify)
                                   .put("company_serial", params.getString("company_serial", ""));
        }).flatMap(param -> AuthRouter.AuthCode(context, param)).flatMap(param -> {
            if (!param.getBoolean("result") && !param.getBoolean("mail_can_verify")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            } else if (param.getBoolean("result")) {
                param.remove("mail_can_verify");
                param.put("mail_can_verify", true);
            }
            
            return Single.just(param);
        }).flatMap(AuthenticationHandler::DatabaseSubmitAuthentication).doOnError(err -> {
            if (!context.response().ended()) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + " " + PresetMessage.ERROR_FAILED.toString());
            }
        }).flatMap(param -> {
            if (param == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_FAILED);
                Shared.getRouterLogger()
                      .warn(context.normalisedPath() + PresetMessage.ERROR_FAILED);
            } else {
                JsonResponse.RespondSuccess(context, "Authentication submitted successfully");
            }
            return Single.just(param);
        }).subscribe(res -> {
            Shared.getRouterLogger().info("router path " + context.normalisedPath() + " processed successfully");
        }, failure -> {
            Shared.getRouterLogger().error(failure.getMessage());
        });
    }
}
