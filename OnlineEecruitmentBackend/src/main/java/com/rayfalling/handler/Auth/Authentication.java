package com.Rayfalling.handler.Auth;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Extensions.DataBaseExt;
import com.Rayfalling.middleware.Utils.sql.SqlQuery;
import io.reactiverse.reactivex.pgclient.PgConnection;
import io.reactiverse.reactivex.pgclient.Row;
import io.reactiverse.reactivex.pgclient.Tuple;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;

public class Authentication {
    /**
     * @param data 传入参数，包含"phone"和"password"的JsonObject
     * @return 0   数据库成功执行
     * -1  数据库执行失败，手机号已存在
     * -2  数据库执行失败，未知错误
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseRegister(JsonObject data) {
        return Shared.getPgPool()
                     .rxGetConnection()
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     })
                     .doAfterSuccess(PgConnection::close)
                     .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("Register"), Tuple.of(data.getString("phone"), data.getString("password"))))
                     .map(res -> {
                         Row row = DataBaseExt.oneOrNull(res);
                         if (row == null)
                             return -2;
                         else if (row.getInteger(0) == 0)
                             return 0;
                         else if (row.getInteger(0) == -1)
                             return -1;
                         return -2;
                     })
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     });
    }
    
    /**
     * @param data 传入参数，包含"phone"和"password"的JsonObject
     * @return id 数据库用户id
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseLogin(JsonObject data) {
        return Shared.getPgPool()
                     .rxGetConnection()
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     })
                     .doAfterSuccess(PgConnection::close)
                     .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("Login"), Tuple.of(data.getString("phone"), data.getString("password"))))
                     .map(res -> {
                         Row row = DataBaseExt.oneOrNull(res);
                         return row != null ? row.getInteger("id") : -1;
                     })
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     });
    }
    
    /**
     * @param username 传入参数，包含"phone"和"password"的JsonObject
     * @return id 数据库用户id
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseSelectId(String username) {
        return Shared.getPgPool()
                     .rxGetConnection()
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     })
                     .doAfterSuccess(PgConnection::close)
                     .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("SelectId"), Tuple.of(username)))
                     .map(res -> {
                         Row row = DataBaseExt.oneOrNull(res);
                         return row != null ? row.getInteger("id") : -1;
                     })
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     });
    }
}
