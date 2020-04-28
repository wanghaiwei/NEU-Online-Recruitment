package com.Rayfalling.middleware.data.Recommend;

import java.util.HashSet;
import java.util.Optional;

public class RecommendMapStorage {
    static HashSet<RecommendMap> recommendMapList;
    
    static {
        recommendMapList = new HashSet<>();
    }
    
    public static HashSet<RecommendMap> getRecommendMapList() {
        return recommendMapList;
    }
    
    /**
     * 查找{@link RecommendMap}
     *
     * @param previous 先前的Id
     * @param next     后面的Id
     */
    public static RecommendMap find(int previous, int next) {
        return recommendMapList.stream()
                               .filter(map -> map.getNextId() == next && map.getSourceId() == previous)
                               .findFirst().orElse(null);
    }
    
    /**
     * 判定是否存在
     *
     * @param previous 先前的Id
     * @param next     后面的Id
     */
    public static boolean exist(int previous, int next) {
        return recommendMapList.stream()
                               .anyMatch(map -> map.getNextId() == next && map.getSourceId() == previous);
    }
    
    /**
     * 判定是否存在
     *
     * @param recommendMap map
     */
    public static boolean exist(RecommendMap recommendMap) {
        return recommendMapList.stream().anyMatch(item -> item.equals(recommendMap));
    }
    
    /**
     * 添加新用户的{@link RecommendMap}
     *
     * @param recommendMap map
     */
    public static void add(RecommendMap recommendMap) {
        recommendMapList.add(recommendMap);
    }
    
    /**
     * 移除{@link RecommendMap}
     *
     * @param previous 先前的Id
     * @param next     后面的Id
     */
    public static void remove(int previous, int next) {
        recommendMapList.stream()
                        .filter(map -> map.getNextId() == next && map.getSourceId() == previous)
                        .findFirst()
                        .ifPresent(map -> recommendMapList.remove(map));
    }
}
