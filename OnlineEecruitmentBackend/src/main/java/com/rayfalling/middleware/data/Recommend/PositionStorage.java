package com.Rayfalling.middleware.data.Recommend;

import java.util.HashSet;

public class PositionStorage {
    static HashSet<Position> positionList;
    
    static {
        positionList = new HashSet<>();
    }
    
    public static HashSet<Position> getPositionList() {
        return positionList;
    }
    
    /**
     * 查找{@link RecommendMap}
     *
     * @param id 职位Id
     */
    public static Position find(int id) {
        return positionList.stream()
                           .filter(position -> position.getId() == id)
                           .findFirst().orElse(null);
    }
    
    /**
     * 判定是否存在
     *
     * @param id 职位Id
     */
    public static boolean exist(int id) {
        return positionList.stream().anyMatch(position -> position.getId() == id);
    }
    
    /**
     * 判定是否存在
     *
     * @param position 职位
     */
    public static boolean exist(Position position) {
        return positionList.stream().anyMatch(item -> item.equals(position));
    }
    
    /**
     * 添加新用户的{@link RecommendMap}
     *
     * @param position 职位
     */
    public static void add(Position position) {
        positionList.add(position);
    }
    
    /**
     * 移除{@link RecommendMap}
     *
     * @param id 职位Id
     */
    public static void remove(int id) {
        positionList.stream()
                    .filter(position -> position.getId() == id)
                    .findFirst()
                    .ifPresent(map -> positionList.remove(map));
    }
}
