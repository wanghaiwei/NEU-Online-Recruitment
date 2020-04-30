package com.Rayfalling.middleware.Utils.Recommend;

import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

import java.util.Map;

public class RecommendUtils {
    /**
     * 时间更细权重
     */
    static int timeWeight = 2;
    /**
     * 最大浏览时间，超过这个数字以后均认为完成一次兴趣度较高的浏览
     */
    static int maxTime = 60;
    /**
     * 时间更新权重最大值
     */
    static int maxUpdateWeight = maxTime * timeWeight;
    /**
     * 正反馈权值最小时限
     */
    static int positiveFeedbackTime = 10;
    /**
     * 负反馈权值最大时限
     */
    static int negativeFeedbackTime = 5;
    
    /**
     * 重新计算用户偏好权重
     *
     * @param weight   用户Id
     * @param category 浏览分类
     * @param second   浏览时长
     */
    public static JsonObject RecomputeWeight(JsonObject weight, int category, int second) {
        JsonObject jsonObject = ScaleWeight(weight);
        Integer current = jsonObject.getInteger(String.valueOf(category));
        if (second >= positiveFeedbackTime) {
            current += Math.min(second * timeWeight, maxUpdateWeight);
        } else if (second <= negativeFeedbackTime) {
            current -= Math.min(second * timeWeight, maxUpdateWeight);
        }
        jsonObject.put(String.valueOf(category), current);
        return NormalizeWeight(jsonObject);
    }
    
    /**
     * 放大用户权重
     */
    private static JsonObject ScaleWeight(@NotNull JsonObject weight) {
        JsonObject jsonObject = weight.copy();
        for (Map.Entry<String, Object> item : jsonObject) {
            item.setValue((Integer) item.getValue() * 1000);
        }
        return jsonObject;
    }
    
    /**
     * 归一化用户权重
     */
    private static JsonObject NormalizeWeight(@NotNull JsonObject weight) {
        int max = Integer.MAX_VALUE, min = Integer.MIN_VALUE;
        for (Map.Entry<String, Object> item : weight) {
            max = Math.max((Integer) item.getValue(), max);
            min = Math.min((Integer) item.getValue(), min);
        }
        JsonObject jsonObject = weight.copy();
        for (Map.Entry<String, Object> item : jsonObject) {
            item.setValue(Normalize((Integer) item.getValue(), max, min));
        }
        return jsonObject;
    }
    
    /**
     * 线性正则化
     */
    private static int Normalize(int value, int max, int min) {
        return (value - min) / (max - min);
    }
}

