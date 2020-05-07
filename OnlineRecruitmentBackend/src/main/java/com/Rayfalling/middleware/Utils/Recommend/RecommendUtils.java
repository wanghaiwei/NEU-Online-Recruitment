package com.Rayfalling.middleware.Utils.Recommend;

import com.Rayfalling.middleware.data.Recommend.Position;
import com.Rayfalling.middleware.data.Recommend.PositionStorage;
import com.Rayfalling.middleware.data.Recommend.RecommendMap;
import com.Rayfalling.middleware.data.Recommend.RecommendMapStorage;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;
import org.jetbrains.annotations.NotNull;

import java.util.*;
import java.util.stream.Collectors;

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
     * TopK推荐
     */
    static int topK = 2;
    /**
     * 生成的推荐列表
     */
    static int recommendSize = 5;
    
    public static void setRecommendSize(int recommendSize) {
        RecommendUtils.recommendSize = recommendSize;
    }
    
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
    
    /**
     * 生成推荐列表
     */
    public static @NotNull List<Position> generateRecommendList(@NotNull JsonObject weight, int positionId) {
        PriorityQueue<Map.Entry<String, Object>> priorityQueue = new PriorityQueue<>(topK, (o1, o2) -> (int) ((Float) o2.getValue() - (Float) o1.getValue()));
        for (Map.Entry<String, Object> item : weight) {
            if (priorityQueue.size() < topK) {
                priorityQueue.offer(item);
            } else if (!priorityQueue.isEmpty() && (Float) priorityQueue.peek().getValue() > (Float) item.getValue()) {
                priorityQueue.poll();
                priorityQueue.offer(item);
            }
        }
        
        //get recommend list
        JsonArray recommendCandidate = new JsonArray();
        while (!priorityQueue.isEmpty()) {
            recommendCandidate.add(new JsonObject().put("category", Integer.valueOf(priorityQueue.peek().getKey()))
                                                   .put("weight", (Float) Objects.requireNonNull(priorityQueue.peek())
                                                                                 .getValue()));
            priorityQueue.poll();
        }
        
        //获取TopK的总权重
        Float totalWeight = 0F;
        for (Object object : recommendCandidate) {
            totalWeight += ((JsonObject) object).getFloat("weight");
        }
        
        //更新选取权值
        for (Object object : recommendCandidate) {
            ((JsonObject) object).put("weight", ((JsonObject) object).getFloat("weight") / totalWeight);
        }
        
        List<Position> RecommendList = new LinkedList<>();
        for (Object object : recommendCandidate) {
            RecommendList.addAll(
                    PositionStorage.getPositionList().stream()
                                   .filter(position -> position.getLabel() == ((JsonObject) object)
                                                                                      .getInteger("category"))
                                   .sorted((o1, o2) -> {
                                       int o1Score = (int) (o1.getTimestamp() - System.currentTimeMillis()) / 100000,
                                               o2Score = (int) (o2.getTimestamp() - System.currentTimeMillis()) / 100000;
                                       if (RecommendMapStorage.exist(positionId, o1.getId())) {
                                           o1Score += RecommendMapStorage.find(positionId, o1.getId())
                                                                         .getHitCount() * 5;
                                       }
                                       if (RecommendMapStorage.exist(positionId, o2.getId())) {
                                           o2Score += RecommendMapStorage.find(positionId, o2.getId())
                                                                         .getHitCount() * 5 ;
                                       }
                                       return o2Score - o1Score + new Random().nextInt() % 100;
                                   }).limit((long) (((JsonObject) object).getFloat("weight") * recommendSize))
                                   .collect(Collectors.toList()));
        }
        return RecommendList;
    }
}

