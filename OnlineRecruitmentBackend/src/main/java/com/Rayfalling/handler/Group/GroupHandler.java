package com.Rayfalling.handler.Group;

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

public class GroupHandler {
    
    /**
     * 数据库查询圈子分类
     *
     * @return 查询结果
     * @author Rayfalling
     */
    public static Single<JsonArray> DatabaseQueryGroupCategory() {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("GroupQueryCategory")))
                       .map(res -> DataBaseExt.mapJsonArray(res, row -> new JsonObject().put("id", row.getInteger("id"))
                                                                                        .put("name", row.getString("name"))))
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库查询圈子分类
     *
     * @return 查询结果
     * @author Rayfalling
     */
    public static Single<JsonArray> DatabaseQueryGroupInfo() {
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("GroupQueryInfo")))
                       .map(res -> DataBaseExt.mapJsonArray(res, row -> new JsonObject().put("id", row.getInteger("id"))
                                                                                        .put("avatar", row.getInteger("logo"))
                                                                                        .put("description", row.getInteger("description"))
                                                                                        .put("name", row.getString("name"))))
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库用户添加圈子
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseNewGroup(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getString("name"), data.getString("group_avatar"),
                data.getString("group_description"), data.getInteger("group_category_id"),
                data.getInteger("user_id"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("GroupNew"), Tuple.of(tuple)))
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
     * 数据库用户搜索圈子
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<JsonArray> DatabaseSearchGroup(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(DataBaseExt.getQueryString(data.getString("content")),
                DataBaseExt.getQueryString(data.getJsonArray("group_category_id")));
        String storeSql = SqlQuery.getQuery("PositionSearch");
        String sql = DataBaseExt.prepareQuery(storeSql, tuple);
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxQuery(sql))
                       .map(res -> {
                           return DataBaseExt.mapJsonArray(res, row -> {
                               return new JsonObject().put("id", row.getInteger("id"))
                                                      .put("name", row.getString("name"))
                                                      .put("logo", row.getString("logo"))
                                                      .put("description", row.getString("description"))
                                                      .put("group_category_id", row.getInteger("group_category_id"));
                           });
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库用户搜索圈子
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseJoinGroup(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(DataBaseExt.getQueryString(data.getString("content")),
                DataBaseExt.getQueryString(data.getJsonArray("group_category_id")));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("GroupJoin"), Tuple.of(tuple)))
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
