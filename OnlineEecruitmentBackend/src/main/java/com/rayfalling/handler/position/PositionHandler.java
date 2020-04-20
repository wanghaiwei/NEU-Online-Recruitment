package com.Rayfalling.handler.position;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Extensions.DataBaseExt;
import com.Rayfalling.middleware.Utils.sql.SqlQuery;
import io.reactiverse.reactivex.pgclient.PgConnection;
import io.reactiverse.reactivex.pgclient.Row;
import io.reactiverse.reactivex.pgclient.Tuple;
import io.reactivex.Single;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

public class PositionHandler {
    /**
     * @return 查询结果
     * @author Rayfalling
     */
    public static Single<JsonArray> DatabaseQueryPositionCategory() {
        return Shared.getPgPool()
                     .rxGetConnection()
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     })
                     .doAfterSuccess(PgConnection::close)
                     .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PositionQueryCategory")))
                     .map(res -> DataBaseExt.mapJsonArray(res, row -> new JsonObject().put("id", row.getInteger("id"))
                                                                                      .put("name", row.getString("name"))))
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     });
    }
    
    /**
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseQueryPositionCategory(@NotNull JsonObject data) {
        io.reactiverse.pgclient.Tuple tuple = io.reactiverse.pgclient.Tuple.of(data.getString("name"),
                data.getString("company"), data.getString("position_des"), data.getString("post_mail"),
                data.getString("location"), data.getString("grade"), data.getInteger("position_cate_id"),
                data.getInteger("user_id"));
        return Shared.getPgPool()
                     .rxGetConnection()
                     .doOnError(err -> {
                         Shared.getDatabaseLogger().error(err);
                         err.printStackTrace();
                     })
                     .doAfterSuccess(PgConnection::close)
                     .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PositionNew"), Tuple.of(tuple)))
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
