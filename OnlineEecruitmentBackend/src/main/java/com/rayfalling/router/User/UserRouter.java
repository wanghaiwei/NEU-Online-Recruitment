package com.Rayfalling.router.User;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Auth.Authentication;
import com.Rayfalling.middleware.JsonResponse;
import com.Rayfalling.middleware.PresetMessage;
import com.Rayfalling.middleware.Utils;
import io.reactivex.Single;
import io.reactivex.disposables.Disposable;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.core.Promise;
import io.vertx.reactivex.ext.web.Router;
import io.vertx.reactivex.ext.web.RoutingContext;

/**
 * 用户相关路由
 *
 * @author rayfalling
 */
public class UserRouter {
    private static Router router;
    private static UserRouter instance = new UserRouter();
    
    //让构造函数为 private，这样该类就不会被实例化
    private UserRouter() {
        router = Router.router(Shared.getInstance().getVertx());
        router.get("/").handler(this::UserIndex);
        router.post("/register").handler(this::UserRegister);
    }
    
    //获取唯一可用的对象
    public static UserRouter getInstance() {
        return instance;
    }
    
    public Router getRouter() {
        return router;
    }
    
    private void UserIndex(RoutingContext context) {
        context.response().end(("This is the index page of user router.").trim());
    }
    
    private void UserRegister(RoutingContext context) {
        Disposable disposable = Single.just(context).map(RoutingContext::getBodyAsJson).doOnError(err -> {
            JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON);
            Shared.getInstance().getRouterLogger().warn(PresetMessage.ERROR_REQUEST_JSON.toString());
        }).map(params -> {
            //check param is null
            String phone = params.getString("phone", "");
            String password = params.getString("password", "");
            
            if (password.equals("") || phone.equals("")) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
                Shared.getInstance().getRouterLogger().warn(PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            }
            
            if (Utils.isMobile(phone)) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_FORMAT_ERROR);
                Shared.getInstance().getRouterLogger().warn(PresetMessage.PHONE_FORMAT_ERROR.toString());
            }
            
            return new JsonObject().put("phone", phone).put("password", password);
        }).flatMap(params -> {
            int result = Authentication.DatabaseRegister(params);
            if (result == 0) {
                JsonResponse.RespondPreset(context, PresetMessage.SUCCESS);
            } else if (result == -1) {
                JsonResponse.RespondPreset(context, PresetMessage.PHONE_REGISTERED_ERROR);
                Shared.getInstance().getRouterLogger().warn(PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
            } else if (result == -2) {
                JsonResponse.RespondPreset(context, PresetMessage.ERROR_UNKNOWN);
                Shared.getInstance().getRouterLogger().warn(PresetMessage.ERROR_UNKNOWN.toString());
            }
            
            return null;
        }).doOnError(err -> {
            JsonResponse.RespondPreset(context, PresetMessage.ERROR_REQUEST_JSON_PARAM);
            Shared.getInstance().getRouterLogger().warn(PresetMessage.ERROR_REQUEST_JSON_PARAM.toString());
        }).subscribe(res -> {
            Promise.promise().complete(res);
        }, failure -> {
            Promise.promise().fail(failure);
        });
    }
}
