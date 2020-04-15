package com.Rayfalling.middleware.data;

import io.vertx.core.json.Json;
import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.Objects;

public class Token {
    
    private final String username;
    private int id;
    private Long createTime;
    private Long expireTime;
    private boolean isExpired = false;
    
    /**
     * 通过username生成Token
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
            this.expireTime = jsonObject.getLong("expireTime");
        } else {
            this.id = -1;
            this.username = string;
            this.createTime = Timestamp.valueOf(LocalDateTime.now()).getTime();
            this.expireTime = new Timestamp(1800000).getTime();
        }
    }
    
    /**
     * 通过username生成Token
     *
     * @param string username or token string
     * @author Rayfalling
     */
    public Token(Integer id, @NotNull String string) {
        this.id = id;
        this.username = string;
        this.createTime = Timestamp.valueOf(LocalDateTime.now()).getTime();
        this.expireTime = new Timestamp(1800000).getTime();
    }
    
    /**
     * 通过username生成Token，
     * 可以自定义过期时间
     *
     * @param username   用户名
     * @param expireTime 过期时间, {@link Long}类型Timestamp
     * @author Rayfalling
     */
    public Token(String username, Long expireTime) {
        this.username = username;
        this.createTime = Timestamp.valueOf(LocalDateTime.now()).getTime();
        this.expireTime = expireTime;
    }
    
    /**
     * 通过username生成Token，
     * 可以自定义过期时间
     *
     * @param jsonObject Token对应String
     * @author Rayfalling
     */
    public Token(JsonObject jsonObject) {
        this.id = jsonObject.getInteger("username");
        this.username = jsonObject.getString("username");
        this.createTime = jsonObject.getLong("createTime");
        this.expireTime = jsonObject.getLong("expireTime");
    }
    
    
    //get set methods
    public String getUsername() {
        return username;
    }
    
    public Long getCreateTime() {
        return createTime;
    }
    
    public Long getExpireTime() {
        return expireTime;
    }
    
    public int getId() {
        return id;
    }
    
    public void setExpireTime(Long expireTime) {
        this.expireTime = expireTime;
    }
    
    /**
     * 设置Token直接过期
     * */
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
        jsonObject.put("username", username)
                  .put("createTime", createTime)
                  .put("expireTime", expireTime);
        return "NEU" + jsonObject.encode();
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Token)) return false;
        Token token = (Token) o;
        return getUsername().equals(token.getUsername()) &&
               getCreateTime().equals(token.getCreateTime()) &&
               getExpireTime().equals(token.getExpireTime());
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(getUsername(), getCreateTime(), getExpireTime());
    }
}
