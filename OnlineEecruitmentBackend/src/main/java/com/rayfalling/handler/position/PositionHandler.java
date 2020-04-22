package com.Rayfalling.handler.Position;

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

import static com.Rayfalling.handler.DatabaseConnection.PgConnectionSingle;

public class PositionHandler {
    /**
     * 数据库查询职位分类
     *
     * @return 查询结果
     * @author Rayfalling
     */
    public static Single<JsonArray> DatabaseQueryPositionCategory() {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PositionQueryCategory")))
                       .map(res -> DataBaseExt.mapJsonArray(res, row -> new JsonObject().put("id", row.getInteger("id"))
                                                                                        .put("name", row.getString("name"))))
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库用户添加职位
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseNewPosition(@NotNull JsonObject data) {
        io.reactiverse.pgclient.Tuple tuple = io.reactiverse.pgclient.Tuple.of(data.getString("name"),
                data.getString("company"), data.getString("position_des"), data.getString("post_mail"),
                data.getString("location"), data.getString("grade"), data.getInteger("position_category_id"),
                data.getInteger("user_id"));
        return PgConnectionSingle()
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
    
    /**
     * 数据库删除职位
     *
     * @return 操作状态
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseDeletePosition(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("user_id"), data.getInteger("position_id"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PositionDelete"), tuple))
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
     * 数据库用户收藏职位
     *
     * @return 操作状态
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseFavourPosition(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("user_id"), data.getInteger("position_id"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PositionFavour"), tuple))
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
