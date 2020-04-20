package com.Rayfalling.middleware.data;

import com.Rayfalling.middleware.Utils.File.FileType;
import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

/**
 * 身份数据枚举类
 */
public enum Identity {
    SUPER_ADMIN(0, 0, "超级管理员"),
    GROUP_ADMIN_HR(100, 1, "圈主-HR"),
    GROUP_ADMIN_STAFF(100, 0, "圈主-员工"),
    COMMON_USER_HR(101, 1, "普通用户-HR"),
    COMMON_USER_STAFF(101, 0, "普通用户-员工"),
    COMMON_USER_UNRECOGNIZED(101, -1, "普通用户-未认证");
    
    int mask, category;
    String description;
    
    Identity(int mask, int category, String description) {
        this.mask = mask;
        this.category = category;
        this.description = description;
    }
    
    /**
     * 将枚举类{@link Identity}转换成{@link JsonObject}
     *
     * @return {@link JsonObject}
     */
    public static JsonObject map2JsonObject(@NotNull Identity identity) {
        return new JsonObject().put("name", identity.name())
                               .put("mask", identity.mask)
                               .put("category", identity.category)
                               .put("description", identity.description);
    }
    
    /**
     * 从{@link JsonObject}转换成枚举类{@link Identity}
     *
     * @return {@link Identity}
     */
    public static Identity mapFromJsonObject(JsonObject object) {
        for (Identity identity : Identity.values()) {
            if (identity.mask == object.getInteger("mask")
                && identity.name().equals(object.getString("name"))
                && identity.category == object.getInteger("category")
                && identity.description.equals(object.getString("description"))) {
                return identity;
            }
        }
        return Identity.COMMON_USER_UNRECOGNIZED;
    }
    
    public static Identity mapFromDatabase(Integer mask, Integer category) {
        mask = mask == null ? 101 : mask;
        category = category == null ? -1 : category;
        
        for (Identity identity : Identity.values()) {
            if (identity.mask == mask && identity.category == category) {
                return identity;
            }
        }
        return Identity.COMMON_USER_UNRECOGNIZED;
    }
    
    public int mapCategory(String category) {
        switch (category) {
            case "HR":
                return 1;
            case "员工":
                return 0;
        }
        return 0;
    }
}
