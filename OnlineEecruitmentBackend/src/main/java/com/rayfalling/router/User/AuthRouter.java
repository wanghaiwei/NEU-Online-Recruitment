package com.Rayfalling.router.User;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Response.JsonResponse;
import com.Rayfalling.middleware.Response.PresetMessage;
import com.Rayfalling.middleware.Utils.Security.EncryptUtils;
import com.Rayfalling.middleware.data.Token;
import com.Rayfalling.middleware.data.TokenStorage;
import io.vertx.reactivex.core.http.Cookie;
import io.vertx.reactivex.ext.web.RoutingContext;
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
}
