package com.Rayfalling.config;

import com.Rayfalling.middleware.Utils.ConfigLoader;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class TimerVerticleConfig extends DeploymentOptions {
    private static TimerVerticleConfig instance;
    
    static {
        try {
            instance = new TimerVerticleConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    JsonObject config;
    
    public TimerVerticleConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("timer");
        setInstances(1);
        setConfig(config);
    }
    
    public static TimerVerticleConfig getInstance() {
        return instance;
    }
    
    public JsonObject getInstanceConfig() {
        return config;
    }
}
