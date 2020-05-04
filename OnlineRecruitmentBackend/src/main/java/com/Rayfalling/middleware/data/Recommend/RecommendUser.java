package com.Rayfalling.middleware.data.Recommend;

import io.vertx.core.json.JsonObject;

public class RecommendUser {
    private final int userId;
    private JsonObject weight;
    
    public RecommendUser(int userId, JsonObject weight) {
        this.userId = userId;
        this.weight = weight;
    }
    
    public JsonObject getWeight() {
        return weight;
    }
    
    public void updateWeight(JsonObject weight) {
        this.weight = weight;
    }
    
    public int getUserId() {
        return userId;
    }
}
