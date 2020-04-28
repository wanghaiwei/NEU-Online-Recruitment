package com.Rayfalling.middleware.data.Recommend;

import io.vertx.core.json.JsonObject;

public class RecommendUser {
    private JsonObject weight;
    private final int userId;
    
    public RecommendUser(int userId, JsonObject weight) {
            this.userId = userId;
            this.weight = weight;
        }
    
    public void Update(int category, float weight) {
        if (this.weight.containsKey(String.valueOf(category))) {
            this.weight.remove(String.valueOf(category));
        }
        this.weight.put(String.valueOf(category), weight);
    }
    
    public JsonObject getWeight() {
        return weight;
    }
    
    public void setWeight(JsonObject weight) {
        this.weight = weight;
    }
    
    public int getUserId() {
        return userId;
    }
}
