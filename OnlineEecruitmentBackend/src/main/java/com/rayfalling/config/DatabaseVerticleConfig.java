package com.Rayfalling.config;

import com.Rayfalling.middleware.Utils.ConfigLoader;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class DatabaseVerticleConfig extends DeploymentOptions {
    private static DatabaseVerticleConfig instance;
    
    static {
        try {
            instance = new DatabaseVerticleConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    JsonObject config;
    
    public DatabaseVerticleConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("database");
        setInstances(1);
        setConfig(config);
    }
    
    public static DatabaseVerticleConfig getInstance() {
        return instance;
    }
    
    public JsonObject getInstanceConfig() {
        return config;
    }
}
