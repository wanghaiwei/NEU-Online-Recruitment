package com.Rayfalling.middleware.data.Recommend;

import java.util.HashSet;
import java.util.Optional;

public class RecommendUserStorage {
    static HashSet<RecommendUser> recommendUsers;
    
    static {
        recommendUsers = new HashSet<>();
    }
    
    public static HashSet<RecommendUser> getRecommendUsers() {
        return recommendUsers;
    }
    
    /**
     * 查找{@link RecommendUser}
     *
     * @param userId 用户Id
     */
    public static RecommendUser find(int userId) {
        return recommendUsers.stream()
                             .filter(user -> user.getUserId() == userId)
                             .findFirst()
                             .orElse(null);
    }
    
    /**
     * 判定是否存在
     *
     * @param userId 用户Id
     */
    public static boolean exist(int userId) {
        return recommendUsers.stream()
                               .anyMatch(user -> user.getUserId() == userId);
    }
    
    /**
     * 判定是否存在
     *
     * @param recommendUser user
     */
    public static boolean exist(RecommendUser recommendUser) {
        return recommendUsers.stream().anyMatch(item -> item.equals(recommendUser));
    }
    
    /**
     * 添加新用户的{@link RecommendUser}
     *
     * @param recommendUser user
     */
    synchronized public static void add(RecommendUser recommendUser) {
        recommendUsers.add(recommendUser);
    }
    
    /**
     * 移除{@link RecommendUser}
     *
     * @param userId 用户Id
     */
    synchronized public static void remove(int userId) {
        recommendUsers.stream()
                      .filter(map -> map.getUserId() == userId)
                      .findFirst()
                      .ifPresent(map -> recommendUsers.remove(map));
    }
}
