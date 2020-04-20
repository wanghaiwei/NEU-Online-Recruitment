package com.Rayfalling.handler.position;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Extensions.DataBaseExt;
import com.Rayfalling.middleware.Utils.sql.SqlQuery;
import io.reactiverse.reactivex.pgclient.PgConnection;
import io.reactivex.Single;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;

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
}
