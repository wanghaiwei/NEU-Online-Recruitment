package com.Rayfalling.middleware.Response;

import com.Rayfalling.Shared;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.ext.web.RoutingContext;

public class JsonResponse {
    /**
     * 以 JSON 格式发起回复。
     * 默认回复code 200
     *
     * @author Rayfalling
     */
    public static void RespondJson(RoutingContext routingContext, Object data) {
        RespondJson(routingContext, 0, 200, data);
    }
    
    private static void RespondJson(RoutingContext routingContext, int code, int status, Object data) {
        if (!(data instanceof JsonObject) && !(data instanceof JsonArray))
            data = JsonObject.mapFrom(data);
        routingContext.response()
                      .putHeader("Content-Type", "application/json")
                      .setStatusCode(status)
                      .end(new JsonObject().put("code", code).put("data", data).encode());
    }
    
    /**
     * 成功回复。
     *
     * @param data 数据
     * @author Rayfalling
     */
    public static void RespondSuccess(RoutingContext routingContext, Object data) {
        RespondJson(routingContext, 0, 200, data);
    }
    
    /**
     * 成功回复。
     *
     * @param msg 信息
     * @author Rayfalling
     */
    public static void RespondSuccess(RoutingContext routingContext, String msg) {
        RespondSuccess(routingContext, new JsonObject().put("msg", msg));
    }
    
    /**
     * 失败回复。
     *
     * @param code 错误代码，取非零值。约定 -1 为服务器内部错误。
     * @param msg  错误信息。
     * @author Rayfalling
     */
    public static void RespondFailure(RoutingContext routingContext, int code, String msg) {
        RespondJson(routingContext, code, 400, new JsonObject().put("msg", msg));
    }
    
    /**
     * 使用预置消息回复。
     *
     * @param presetMessage 预置消息。
     * @author Rayfalling
     */
    public static void RespondPreset(final RoutingContext routingContext, final PresetMessage presetMessage) {
        try {
            presetMessage.apply(() -> {
                RespondJson(routingContext, presetMessage.code,
                        presetMessage.code == 0 ? 200 : 400,
                        new JsonObject().put("msg", presetMessage.description));
                return presetMessage;
            });
        } catch (Exception e) {
            Shared.getRouterLogger().error(e.getMessage());
            e.printStackTrace();
        }
        
    }
}
