package com.rayfalling.config;

import com.rayfalling.middleware.ConfigLoader;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class MainRouterConfig extends DeploymentOptions {
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

    private static MainRouterConfig instance;

    static {
        try {
            instance = new MainRouterConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static MainRouterConfig getInstance() {
        return instance;
    }

    public MainRouterConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("mainRouter");
        setConfig(config);
        logRequests = config.getBoolean("logRequests");
        sessionKey = config.getString("sessionKey");
        tokenSalt = config.getString("tokenSalt");
    }

    public String getSessionKey(){
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
