package com.Rayfalling.router.User;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Auth.Authentication;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.Utils.Security.EncryptUtils;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.middleware.data.TokenStorage;
import com.Rayfalling.middleware.data.VerifyCode;
import io.reactiverse.pgclient.Tuple;
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
        if (!TokenStorage.exist(sessionToken) || !TokenStorage.exist(cookieToken)) {
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
    
    public static Single<JsonObject> CheckToken(RoutingContext context, JsonObject param) {
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
}
