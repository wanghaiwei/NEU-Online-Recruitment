package com.Rayfalling.handler.Auth;

import com.Rayfalling.Shared;
import io.reactiverse.reactivex.pgclient.PgConnection;
import io.vertx.core.json.JsonObject;

@SuppressWarnings("ResultOfMethodCallIgnored")
public class Authentication {
    /**
     * @param data 传入参数，包含"phone"和"password"的JsonObject
     * @return 0   数据库成功执行
     * -1  数据库执行失败，手机号已存在
     * -2  数据库执行失败，未知错误
     */
    public static int DatabaseRegister(JsonObject data) {
        Shared.getInstance()
              .getPgPool()
              .rxGetConnection()
              .doOnError(err -> {
                  Shared.getInstance().getDatabaseLogger().error(err);
                  err.printStackTrace();
              })
              .doAfterSuccess(PgConnection::close)
              .flatMap(conn -> {
                  conn.rxPreparedQuery();
                  return null;
              })
              .map(res -> {
                  return 0;
              })
              .doOnError(err -> {
                  Shared.getInstance().getDatabaseLogger().error(err);
                  err.printStackTrace();
              });
        
        
        return 0;
    }
}
