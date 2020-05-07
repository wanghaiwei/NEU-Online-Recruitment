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
    static int topK = 3;
    /**
     * 生成的推荐列表
     */
    static int recommendSize = 10;
    
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
        Double current = jsonObject.getDouble(String.valueOf(category));
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
            item.setValue((Double) item.getValue() * 1000);
        }
        return jsonObject;
    }
    
    /**
     * 归一化用户权重
     */
    private static JsonObject NormalizeWeight(@NotNull JsonObject weight) {
        double total = 0.0D;
        JsonObject jsonObject = weight.copy();
        for (Map.Entry<String, Object> item : jsonObject) {
            total += (Double) item.getValue();
        }
        for (Map.Entry<String, Object> item : jsonObject) {
            item.setValue((Double) item.getValue() / total);
        }
        return jsonObject;
    }
    
    /**
     * 生成推荐列表
     */
    @SuppressWarnings("RedundantCast")
    public static @NotNull List<Position> generateRecommendList(@NotNull JsonObject weight, int positionId) {
        PriorityQueue<Map.Entry<String, Object>> priorityQueue = new PriorityQueue<>(topK, (o1, o2) -> (int) ((Double) o2.getValue() - (Double) o1.getValue()));
        for (Map.Entry<String, Object> item : weight) {
            if (priorityQueue.size() < topK) {
                priorityQueue.offer(item);
            } else if (!priorityQueue.isEmpty() && (Double) priorityQueue.peek()
                                                                         .getValue() > (Double) item.getValue()) {
                priorityQueue.poll();
                priorityQueue.offer(item);
            } else if (!priorityQueue.isEmpty() && priorityQueue.peek().getValue().equals(item.getValue())) {
                if (new Random().nextInt() % 2 == 0) {
                    priorityQueue.poll();
                    priorityQueue.offer(item);
                }
            }
        }
        
        //get recommend list
        JsonArray recommendCandidate = new JsonArray();
        while (!priorityQueue.isEmpty()) {
            recommendCandidate.add(new JsonObject().put("category", Integer.valueOf(priorityQueue.peek().getKey()))
                                                   .put("weight", (Double) Objects.requireNonNull(priorityQueue.peek())
                                                                                  .getValue()));
            priorityQueue.poll();
        }
        
        //获取TopK的总权重
        Double totalWeight = 0D;
        for (Object object : recommendCandidate) {
            totalWeight += ((JsonObject) object).getDouble("weight");
        }
        
        //更新选取权值
        for (Object object : recommendCandidate) {
            ((JsonObject) object).put("weight", ((JsonObject) object).getDouble("weight") / totalWeight);
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
                                                                         .getHitCount() * 5;
                                       }
                                       return o2Score - o1Score + new Random().nextInt() % 100;
                                   }).limit((long) (((JsonObject) object).getFloat("weight") * recommendSize))
                                   .collect(Collectors.toList()));
        }
        return RecommendList;
    }
}

