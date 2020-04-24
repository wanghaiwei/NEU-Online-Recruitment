package com.Rayfalling.router.User;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Auth.UserInfoHandler;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.Utils.Security.EncryptUtils;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.middleware.data.TokenStorage;
import com.Rayfalling.middleware.data.VerifyCode;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.core.http.Cookie;
import io.vertx.reactivex.ext.web.RoutingContext;
import io.vertx.reactivex.ext.web.Session;
import org.jetbrains.annotations.NotNull;

/**
 * 用户登录状态鉴权路由
 */
public class AuthRouter {
    /**
     * 验证用户Token
     */
    public static void AuthToken(@NotNull RoutingContext context) {
        Token sessionToken = context.session().get("token");
        Token cookieToken = EncryptUtils.Decrypt2Token(context.getCookie("token").getValue());
        if (!TokenStorage.exist(sessionToken) || !TokenStorage.exist(cookieToken) || sessionToken.getId() == -1) {
            JsonResponse.RespondPreset(context, PresetMessage.ERROR_TOKEN_FAKED);
            Shared.getRouterLogger()
                  .warn(context.normalisedPath() + " " + PresetMessage.ERROR_TOKEN_FAKED.toString());
        }
        Token storeToken = TokenStorage.find(sessionToken);
        if (storeToken.isExpired()) {
            JsonResponse.RespondPreset(context, PresetMessage.ERROR_TOKEN_EXPIRED);
            Shared.getRouterLogger()
                  .warn(context.normalisedPath() + " " + PresetMessage.ERROR_TOKEN_FAKED.toString());
        } else {
            storeToken.UpdateSession();
            context.session().remove("token");
            context.session().put("token", storeToken);
            context.removeCookie("token");
            context.addCookie(Cookie.cookie("token", EncryptUtils.EncryptFromToken(storeToken)));
        }
        
        context.next();
    }
    
    /**
     * 校验用户验证码是否正确
     *
     * @param context 路由上下文,包含Session信息
     * @param param   {@link JsonObject} 包含VerifyCode字段的Json
     */
    public static Single<JsonObject> AuthCode(RoutingContext context, JsonObject param) {
        return Single.just(param).map(res -> {
            Session session = context.session();
            String phone = param.getString("phone");
            if (session.data().containsKey("Code")) {
                VerifyCode.Code code = session.get("Code");
                VerifyCode.Code storageCode = VerifyCode.getInstance().find(phone);
                //防止劫持
                if (storageCode.equals(code)) {
                    if (code.isExpired()) {
                        JsonResponse.RespondPreset(context, PresetMessage.ERROR_VERIFY_CODE_EXPIRED);
                        Shared.getRouterLogger()
                              .warn(context.normalisedPath() + ": User: " + phone + ": " + PresetMessage.ERROR_VERIFY_CODE_EXPIRED
                                                                                                   .getMessage());
                        return param.put("result", false);
                    }
                    if (!code.getCode().equals(param.getString("VerifyCode", ""))) {
                        JsonResponse.RespondPreset(context, PresetMessage.ERROR_VERIFY_CODE_INCORRECT);
                        Shared.getRouterLogger()
                              .warn(context.normalisedPath() + ": User: " + phone + ": " + PresetMessage.ERROR_VERIFY_CODE_INCORRECT
                                                                                                   .getMessage());
                        return param.put("result", false);
                    }
                    return param.put("result", true);
                } else {
                    JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                    Shared.getRouterLogger().warn(context.normalisedPath() + PresetMessage.ERROR_UNKNOWN.toString());
                    return param.put("result", false);
                }
            } else {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getRouterLogger().warn(context.normalisedPath() + PresetMessage.ERROR_UNKNOWN.toString());
                return param.put("result", false);
            }
        });
    }
    
    /**
     * 校验用户发布额度
     */
    @SuppressWarnings("ResultOfMethodCallIgnored")
    public static void AuthQuota(@NotNull RoutingContext context) {
        Token sessionToken = context.session().get("token");
        UserInfoHandler.DatabaseUserQuota(new JsonObject().put("user_id", sessionToken.getId())).flatMap(result -> {
            if (result <= 0) {
                JsonResponse.RespondPreset(context, PresetMessage.OUT_OF_POST_QUOTA_ERROR);
                Shared.getRouterLogger()
                      .warn(sessionToken.getUsername() + " " + PresetMessage.OUT_OF_POST_QUOTA_ERROR
                                                                       .toString());
            }
            context.next();
            return Single.just(result);
        }).subscribe(res -> {
            Shared.getRouterLogger().info(sessionToken.getUsername() + " quota verified");
        }, failure -> {
            Shared.getRouterLogger().info(sessionToken.getUsername() + " quota verified failed");
        });
    }
}
