package com.Rayfalling.config;

import com.Rayfalling.middleware.Utils.ConfigLoader;
import com.Rayfalling.middleware.data.Token;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class MainRouterConfig extends DeploymentOptions {
    private static MainRouterConfig instance;
    
    static {
        try {
            instance = new MainRouterConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    Boolean logRequests;
    /**
     * Session Key
     */
    String sessionKey;
    /**
     * Token Salt
     */
    String tokenSalt;
    JsonObject config;
    Long expireTime;
    
    public MainRouterConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("mainRouter");
        setConfig(config);
        logRequests = config.getBoolean("logRequests");
        sessionKey = config.getString("sessionKey");
        tokenSalt = config.getString("tokenSalt");
        expireTime = config.getLong("expireTime");
        Token.setExpireTime(expireTime);
    }
    
    public static MainRouterConfig getInstance() {
        return instance;
    }
    
    public String getSessionKey() {
        return sessionKey;
    }
    
    public Boolean getLogRequests() {
        return logRequests;
    }
    
    public String getTokenSalt() {
        return tokenSalt;
    }
    
    public JsonObject getInstanceConfig() {
        return config;
    }
}
