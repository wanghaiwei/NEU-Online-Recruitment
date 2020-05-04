package com.Rayfalling.handler.Admin;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Extensions.DataBaseExt;
import com.Rayfalling.middleware.Utils.sql.SqlQuery;
import io.reactiverse.reactivex.pgclient.Row;
import io.reactiverse.reactivex.pgclient.Tuple;
import io.reactivex.Single;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

import static com.Rayfalling.handler.DatabaseConnection.PgConnectionSingle;

public class AdminHandler {
    
    /**
     * 数据库查询身份认证选项
     *
     * @return 查询结果
     * @author Rayfalling
     */
    public static Single<JsonArray> DatabaseQueryAuth(JsonObject data) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AdminFetchAuth")))
                       .map(res -> DataBaseExt.mapJsonArray(res, row -> {
                           return new JsonObject().put("id", row.getInteger("id"))
                                                  .put("mail", row.getString("mail"))
                                                  .put("company", row.getString("company"))
                                                  .put("user_id", row.getInteger("user_id"))
                                                  .put("identity", row.getString("identity"))
                                                  .put("position", row.getString("position"))
                                                  .put("company_serial", row.getString("company_serial"))
                                                  .put("mail_can_verify", row.getBoolean("mail_can_verify"))
                                                  .put("end_time", DataBaseExt
                                                                           .getLocalDateTimeToTimestamp(row, "end_time"))
                                                  .put("begin_time", DataBaseExt
                                                                             .getLocalDateTimeToTimestamp(row, "begin_time"));
                       }))
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库圈子置顶动态
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Boolean> DatabaseAdminPinPost(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("post_id"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AdminPinPost"), tuple))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           return row != null && row.getInteger(0) > 0;
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库查询身份认证选项
     *
     * @return 查询结果
     * @author Rayfalling
     */
    public static Single<JsonArray> DatabaseQueryUser(JsonObject data) {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AdminFetchUser")))
                       .map(res -> DataBaseExt.mapJsonArray(res, row -> {
                           return new JsonObject().put("avatar", row.getString("avatar"))
                                                  .put("user_id", row.getInteger("user_id"))
                                                  .put("username", row.getString("username"))
                                                  .put("nickname", row.getString("nickname"))
                                                  .put("description", row.getString("description"))
                                                  .put("register_time", DataBaseExt
                                                                                .getLocalDateTimeToTimestamp(row, "register_time"));
                       }))
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库圈子置顶动态
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Boolean> DatabaseAdminConfirmAuth(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("id"), data.getInteger("status"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AdminConfirmAuth"), tuple))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           return row != null && row.getInteger(0) > 0;
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库圈子置顶动态
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Boolean> DatabaseAdminUserBan(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("user_id"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AdminUserBan"), tuple))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           return row != null && row.getInteger(0) > 0;
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库圈子置顶动态
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Boolean> DatabaseAdminUserSuper(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("user_id"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("AdminUserSuper"), tuple))
                       .map(res -> {
                           Row row = DataBaseExt.oneOrNull(res);
                           return row != null && row.getInteger(0) > 0;
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
}
