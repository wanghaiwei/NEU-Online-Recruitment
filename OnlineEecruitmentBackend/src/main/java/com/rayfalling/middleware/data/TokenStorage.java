package com.Rayfalling.middleware.data;

import java.util.LinkedList;
import java.util.Optional;

public class TokenStorage {
    static TokenStorage instance = new TokenStorage();
    LinkedList<Token> tokenList;
    
    private TokenStorage() {
        tokenList = new LinkedList<>();
    }
    
    public static TokenStorage getInstance() {
        return instance;
    }
    
    /**
     * 查找的用户{@link Token}
     *
     * @param username 用户名
     */
    public Token find(String username) {
        Optional<Token> result = tokenList.stream()
                                          .filter(obj -> obj.getUsername().equals(username))
                                          .findFirst();
        return result.orElse(null);
    }
    
    /**
     * 移除过期或登出的用户{@link Token}
     *
     * @param token 用户Token
     */
    public void add(Token token) {
        tokenList.add(token);
    }
    
    /**
     * 移除过期或登出的用户{@link Token}
     *
     * @param username 用户名
     */
    public void remove(String username) {
        tokenList.stream()
                 .filter(obj -> obj.getUsername().equals(username))
                 .findFirst()
                 .ifPresent(token -> tokenList.remove(token));
    }
}
