package com.Rayfalling.middleware;

import com.Rayfalling.Shared;
import io.reactiverse.reactivex.pgclient.PgRowSet;
import io.reactiverse.reactivex.pgclient.Row;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;

import java.lang.reflect.Method;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;

public class DataBaseExt {
    
    /**
     * 将结果集映射为 JSON 数组对象。
     *
     * @param pgRowSet Postgresql查询结果
     * @param method   mapper方法，需要返回{@code JsonObject}
     * @author Rayfalling
     */
    public static JsonArray mapJsonArray(PgRowSet pgRowSet, Method method) {
        JsonArray jsonArray = new JsonArray();
        for (Row row : pgRowSet) {
            try {
                jsonArray.add((JsonObject) method.invoke(row));
            } catch (Exception e) {
                Shared.getInstance().getLogger().error(e.getMessage());
                e.printStackTrace();
            }
        }
        return jsonArray;
    }
    
    /**
     * 若结果集仅包含一条记录，则返回该记录，否则返回空值。
     *
     * @param pgRowSet Postgresql查询结果
     * @author Rayfalling
     */
    public static Row oneOrNull(PgRowSet pgRowSet) {
        return pgRowSet.size() == 1 ? pgRowSet.iterator().next() : null;
    }
    
    /**
     * 将数据库中获取的date转换到timestamp
     *
     * @param row  Postgresql查询结果
     * @param name key的名字
     * @author Rayfalling
     */
    public static Long dateToTimestamp(Row row, String name) {
        return Timestamp.valueOf(((LocalDate) row.getValue(name)).atStartOfDay()).getTime();
    }
    
    /**
     * 将数据库中的DateTime转换到timestamp.便于JSON序列化
     *
     * @param row       Postgresql查询结果
     * @param fieldName key的名字
     * @author Rayfalling
     */
    public static Long getLocalDateTimeToTimestamp(Row row, String fieldName) {
        return Timestamp.valueOf((LocalDateTime) row.getValue(fieldName)).getTime();
    }
    
    /**
     * 将 {@code Long} 型的 Timestamp 转为 {@code LocalDateTime}。
     *
     * @param timestamp timestamp
     * @author Rayfalling
     */
    public static LocalDateTime toLocalDateTime(Long timestamp) {
        return LocalDateTime.ofInstant(Instant.ofEpochMilli(timestamp), ZoneId.systemDefault());
    }
    
    /**
     * 将 {@code Long} 型的 Timestamp 转为 {@code LocalDate}。
     *
     * @param timestamp timestamp
     * @author Rayfalling
     */
    public static LocalDate toLocalDate(Long timestamp) {
        return toLocalDateTime(timestamp).toLocalDate();
    }
    
    /**
     * 设置 {@code JsonObject} 中给定key的默认值。
     *
     * @param jsonObject timestamp
     * @param key        key的名字
     * @param value      默认值
     * @author Rayfalling
     */
    public static void setDefault(JsonObject jsonObject, String key, Object value) {
        if (!jsonObject.containsKey(key)) {
            jsonObject.put("key", value);
        }
    }
    
    /**
     * 获取 {@code JsonObject} 中给定key的默认值。
     *
     * @param jsonObject timestamp
     * @param key        key的名字
     * @author Rayfalling
     */
    @SuppressWarnings("unchecked")
    public static <Type> Type getOrNull(JsonObject jsonObject, String key) {
        if (jsonObject.containsKey(key)) {
            return (Type) jsonObject.getValue(key);
        } else return null;
    }
}
