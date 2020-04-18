package com.Rayfalling.handler.Auth;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Extensions.DataBaseExt;
import com.Rayfalling.middleware.Utils.sql.SqlQuery;
import com.Rayfalling.middleware.data.Identity;
import io.reactiverse.reactivex.pgclient.PgConnection;
import io.reactiverse.reactivex.pgclient.Row;
import io.reactiverse.reactivex.pgclient.Tuple;
import io.reactivex.Single;
import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

public class UserInfo {
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
        
        return Shared.getPgPool()
                     .rxGetConnection()
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     })
                     .doAfterSuccess(PgConnection::close)
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
     * @param data 传入参数，包含"username"
     * @return 0   数据库成功执行
     * @author Rayfalling
     */
    public static Single<Identity> DatabaseUserIdentity(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getString("username"));
        
        return Shared.getPgPool()
                     .rxGetConnection()
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     })
                     .doAfterSuccess(PgConnection::close)
                     .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("UserQueryIdentity"), tuple))
                     .map(res -> {
                         Row row = DataBaseExt.oneOrNull(res);
                         return Identity.COMMON_USER_STAFF;
                     })
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     });
    }
    
    //TODO 增加身份查询相关
    //TODO 修正更新个人信息时发布职位额度问题
}
