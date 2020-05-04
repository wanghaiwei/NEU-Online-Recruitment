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

public class UserInfoHandler {
    /**
     * @param data 传入参数，包含"username"和"nickname"的JsonObject
     * @return 0   数据库成功执行
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseUserInfoUpdate(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getString("username"),
                data.getString("nickname"),
                data.getString("gender"),
                data.getString("user_description"),
                data.getString("user_avatar"),
                data.getInteger("expected_career_id"));
        
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("UserUpdateInfo"), tuple))
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
     * @param data 传入参数，包含"phone"的JsonObject
     * @return id 数据库用户id
     * @author Rayfalling
     */
    public static Single<JsonObject> DatabaseUserQueryIdentity(JsonObject data) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AuthQueryIdentity"), Tuple.of(data.getString("phone"))))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           if (row == null) return data.put("result", false);
                           data.put("result", true).put("user_identity", row.getInteger("user_identity"))
                               .put("auth_identity", row.getInteger("auth_identity"));
                           return data;
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * @param data 传入参数，包含"user_id"的JsonObject
     * @return id 数据库用户id
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseUserQuota(JsonObject data) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("UserQueryQuota"), Tuple.of(data.getInteger("user_id"))))
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
     * @param data 传入参数，包含"user_id"的JsonObject
     * @return id 数据库用户id
     * @author Rayfalling
     */
    public static Single<JsonObject> DatabaseUserProfile(JsonObject data) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("UserProfile"), Tuple.of(data.getInteger("user_id"))))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           return row == null ? new JsonObject() : new JsonObject()
                                                                           .put("avatar", row.getString("avatar"))
                                                                           .put("nickname", row.getString("nickname"))
                                                                           .put("description", row.getString("description"));
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
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("UserUpdatePwd"), tuple))
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
