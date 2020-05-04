package com.Rayfalling.config;

import com.Rayfalling.middleware.Utils.ConfigLoader;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class MainVerticleConfig extends DeploymentOptions {
    private static MainVerticleConfig instance;
    
    static {
        try {
            instance = new MainVerticleConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    JsonObject config;
    
    private MainVerticleConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("server");
        setInstances(config.getInteger("instance"));
        setConfig(config.getJsonObject("listen"));
    }
    
    public static MainVerticleConfig getInstance() {
        return instance;
    }
    
    public JsonObject getInstanceConfig() {
        return config;
    }
}
