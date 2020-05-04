package com.Rayfalling.middleware.data;

import java.util.LinkedList;
import java.util.Optional;

public class TokenStorage {
    static LinkedList<Token> tokenList;
    
    static {
        tokenList = new LinkedList<>();
    }
    
    /**
     * 查找的用户{@link Token}
     *
     * @param username 用户名
     */
    public static Token find(String username) {
        Optional<Token> result = tokenList.stream()
                                          .filter(obj -> obj.getUsername().equals(username))
                                          .findFirst();
        return result.orElse(null);
    }
    
    /**
     * 查找的用户{@link Token}
     *
     * @param token 用户Token
     */
    public static Token find(Token token) {
        return tokenList.stream()
                        .filter(obj -> obj.equals(token))
                        .findFirst()
                        .orElse(null);
    }
    
    /**
     * 判定Token是否存在
     *
     * @param token 用户Token
     */
    public static boolean exist(Token token) {
        return tokenList.stream().anyMatch(item -> item.equals(token));
    }
    
    /**
     * 判定Token是否存在
     *
     * @param username 用户名
     */
    public static boolean exist(String username) {
        return tokenList.stream().anyMatch(item -> item.getUsername().equals(username));
    }
    
    /**
     * 添加新用户的{@link Token}
     *
     * @param token 用户Token
     */
    synchronized public static void add(Token token) {
        tokenList.add(token);
    }
    
    /**
     * 移除过期或登出的用户{@link Token}
     *
     * @param username 用户名
     */
    synchronized public static void remove(String username) {
        tokenList.stream()
                 .filter(obj -> obj.getUsername().equals(username))
                 .findFirst()
                 .ifPresent(token -> tokenList.remove(token));
    }
}
