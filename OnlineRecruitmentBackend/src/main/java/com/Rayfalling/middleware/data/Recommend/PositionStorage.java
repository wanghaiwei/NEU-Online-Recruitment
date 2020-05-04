package com.Rayfalling.middleware.data.Recommend;

import java.sql.Timestamp;
import java.util.Arrays;
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
     * 查找{@link Position}
     *
     * @param id 职位Id
     */
    synchronized public static Position find(int id) {
        return positionList.stream()
                           .filter(position -> position.getId() == id)
                           .findFirst().orElse(null);
    }
    
    /**
     * 判定是否存在
     *
     * @param id 职位Id
     */
    synchronized public static boolean exist(int id) {
        return positionList.stream().anyMatch(position -> position.getId() == id);
    }
    
    /**
     * 判定是否存在
     *
     * @param position 职位
     */
    synchronized public static boolean exist(Position position) {
        return positionList.stream().anyMatch(item -> item.equals(position));
    }
    
    /**
     * 添加新用户的{@link RecommendMap}
     *
     * @param position 职位
     */
    synchronized public static void add(Position position) {
        positionList.add(position);
    }
    
    /**
     * 移除{@link Position}
     *
     * @param id 职位Id
     */
    synchronized public static void remove(int id) {
        positionList.stream()
                    .filter(position -> position.getId() == id)
                    .findFirst()
                    .ifPresent(map -> positionList.remove(map));
    }
    
    synchronized public static void RemoveOutdated() {
        Position[] array = new Position[positionList.size()];
        positionList.toArray(array);
        Arrays.sort(array, (itemA, itemB) -> (int) (Timestamp.valueOf(itemA.getLocalDateTime()).getTime()
                                                    - Timestamp.valueOf(itemB.getLocalDateTime()).getTime()));
        if (array.length >= 500) {
            positionList.clear();
            Arrays.stream(array).skip(array.length - 500).forEach(item -> {
                positionList.add(item);
            });
        }
    }
}
