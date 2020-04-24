package com.Rayfalling.handler.Auth;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Extensions.DataBaseExt;
import com.Rayfalling.middleware.Utils.sql.SqlQuery;
import io.reactiverse.reactivex.pgclient.Row;
import io.reactiverse.reactivex.pgclient.Tuple;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

import static com.Rayfalling.handler.DatabaseConnection.PgConnectionSingle;

public class AuthenticationHandler {
    /**
     * 数据库用户注册
     *
     * @param data 传入参数，包含"phone"和"password"的JsonObject
     * @return 0   数据库成功执行
     * -1  数据库执行失败，手机号已存在
     * -2  数据库执行失败，未知错误
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseUserRegister(JsonObject data) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AuthRegister"), Tuple.of(data.getString("phone"), data.getString("password"))))
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
     * 数据库用户登录
     *
     * @param data 传入参数，包含"phone"和"password"的JsonObject
     * @return id 数据库用户id
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseUserLogin(JsonObject data) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AuthLogin"), Tuple.of(data.getString("phone"), data.getString("password"))))
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
     * 数据库查询用户ID
     *
     * @param username 传入参数，用户名
     * @return id 数据库用户id
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseUserId(String username) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("UserQueryId"), Tuple.of(username)))
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
     * 数据库用户重置密码
     *
     * @param data 传入参数，包含"phone"和"pwd_new"的JsonObject
     * @return 执行状态
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseResetPwd(JsonObject data) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AuthResetPwd"), Tuple.of(data.getString("phone"), data.getString("pwd_new"))))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           return row != null ? row.getInteger(0) : -1;
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库用户更新密码
     *
     * @param data 传入参数，包含"phone","pwd_new"和"pwd_old"的JsonObject
     * @return 执行状态
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseUpdatePwd(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getString("phone"), data.getString("pwd_old"), data.getString("pwd_new"));
        
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AuthUpdatePwd"), tuple))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           return row != null ? row.getInteger(0) : -1;
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库用户提交认证
     *
     * @param data 传入参数，包含"username","identity","company","position","mail","mail_can_verify"和"company_serial"的JsonObject
     * @return 执行状态
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseSubmitAuthentication(@NotNull JsonObject data) {
        io.reactiverse.pgclient.Tuple tuple = io.reactiverse.pgclient.Tuple.of(data.getString("username"),
                data.getInteger("identity"),
                data.getString("company"),
                data.getString("position"),
                data.getString("mail"),
                data.getBoolean("mail_can_verify"),
                data.getString("company_serial"));
        
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("UserSubmitAuthentication"), new Tuple(tuple)))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           return row != null ? row.getInteger(0) : -1;
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
}
