package com.Rayfalling.handler.Post;

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

public class PostHandler {
    
    /**
     * 数据库用户查询圈子动态
     *
     * @return 查询结果 {@link JsonArray}
     * @author Rayfalling
     */
    public static Single<JsonArray> DatabaseFetchAll(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("group_id"), data.getString("sort_col").equals("hottest") ? 0 : 1);
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PositionNew"), Tuple.of(tuple)))
                       .map(res -> {
                           return DataBaseExt.mapJsonArray(res, row -> {
                               return new JsonObject().put("id", row.getInteger("id"))
                                                      .put("content", row.getString("content"))
                                                      .put("user_id", row.getInteger("user_id"))
                                                      .put("group_id", row.getInteger("group_id"))
                                                      .put("is_pinned", row.getBoolean("is_pinned"))
                                                      .put("like_number", row.getInteger("like_number"))
                                                      .put("comment_number", row.getInteger("comment_number"))
                                                      .put("favourite_number", row.getInteger("favourite_number"))
                                                      .put("timestamp", DataBaseExt
                                                                                .getLocalDateTimeToTimestamp(row, "timestamp"));
                           });
                       })
                       .doOnError(err -> {
                           Shared.getDatabaseLogger().error(err);
                           err.printStackTrace();
                       });
    }
    
    /**
     * 数据库用户发布动态
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseNewPost(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("group_id"), data.getInteger("user_id"), data.getString("content"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PostNewPost"), tuple))
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
     * 数据库用户删除动态
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseDeletePost(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("post_id"), data.getInteger("user_id"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PostDeletePost"), tuple))
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
     * 数据库用户删除动态
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Integer> DatabaseLikePost(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("post_id"), data.getInteger("user_id"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PostLikePost"), tuple))
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
     * 数据库用户评论动态
     *
     * @return 包含成功的ID的 {@link JsonObject}
     * @author Rayfalling
     */
    public static Single<Integer> DatabasePostComment(@NotNull JsonObject data) {
        Tuple tuple = Tuple.of(data.getInteger("post_id"), data.getInteger("user_id"), data.getString("content"));
        return PgConnectionSingle()
                       .flatMap(conn -> conn.rxPreparedQuery(SqlQuery.getQuery("PostComment"), tuple))
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
