package com.Rayfalling.middleware.data;

import io.vertx.core.json.Json;
import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.Objects;

public class Token {
    
    static Long expireTime;
    private final String username;
    private final int id;
    private Long createTime;
    private Identity identity;
    private boolean isExpired = false;
    
    /**
     * 通过Token String生成Token
     *
     * @param string username or token string
     * @author Rayfalling
     */
    public Token(@NotNull String string) {
        if (string.startsWith("NEU")) {
            JsonObject jsonObject = JsonObject.mapFrom(Json.decodeValue(string.replace("NEU", "")));
            this.id = jsonObject.getInteger("id");
            this.username = jsonObject.getString("username");
            this.createTime = jsonObject.getLong("createTime");
            this.identity = Identity.mapFromJsonObject(jsonObject.getJsonObject("identity"));
        } else {
            this.id = -1;
            this.username = string;
            this.identity = Identity.COMMON_USER_UNRECOGNIZED;
            this.createTime = Timestamp.valueOf(LocalDateTime.now()).getTime();
        }
    }
    
    /**
     * 通过username和id生成Token
     *
     * @param id       用户id
     * @param string   username or token string
     * @param identity 用户身份
     * @author Rayfalling
     */
    public Token(Integer id, @NotNull String string, Identity identity) {
        this.id = id;
        this.username = string;
        this.identity = identity;
        this.createTime = Timestamp.valueOf(LocalDateTime.now()).getTime();
    }
    
    /**
     * 通过username生成Token，
     * 可以自定义过期时间
     *
     * @param jsonObject Token对应String
     * @author Rayfalling
     */
    public Token(@NotNull JsonObject jsonObject) {
        this.id = jsonObject.getInteger("id");
        this.username = jsonObject.getString("username");
        this.createTime = jsonObject.getLong("createTime");
        this.identity = Identity.mapFromJsonObject(jsonObject.getJsonObject("identity"));
    }
    
    public static void setExpireTime(Long newExpireTime) {
        expireTime = newExpireTime;
    }
    
    //get set methods
    public String getUsername() {
        return username;
    }
    
    public Long getCreateTime() {
        return createTime;
    }
    
    public int getId() {
        return id;
    }
    
    public Identity getIdentity() {
        return identity;
    }
    
    public void setIdentity(Identity identity) {
        this.identity = identity;
    }
    
    /**
     * 设置Token直接过期
     */
    public void setExpired() {
        isExpired = true;
    }
    
    /**
     * 判定Token是否过期
     */
    public boolean isExpired() {
        return isExpired || Timestamp.valueOf(LocalDateTime.now()).getTime() > createTime + expireTime;
    }
    
    /**
     * 更新Token时间
     */
    public void UpdateSession() {
        this.createTime = Timestamp.valueOf(LocalDateTime.now()).getTime();
    }
    
    @Override
    public String toString() {
        JsonObject jsonObject = new JsonObject();
        jsonObject.put("id", id)
                  .put("username", username)
                  .put("createTime", createTime)
                  .put("identity", Identity.map2JsonObject(identity));
        return "NEU" + jsonObject.encode();
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Token)) return false;
        Token token = (Token) o;
        return getId() == token.getId() &&
               getUsername().equals(token.getUsername()) &&
               getCreateTime().equals(token.getCreateTime()) &&
               getIdentity().equals(token.getIdentity());
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(getUsername(), getCreateTime(), getIdentity());
    }
}
