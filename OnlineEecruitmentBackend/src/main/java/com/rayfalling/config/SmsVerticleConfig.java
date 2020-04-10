package com.Rayfalling.config;

import com.Rayfalling.middleware.Utils.ConfigLoader;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class SmsVerticleConfig extends DeploymentOptions {
    private static SmsVerticleConfig instance;
    
    static {
        try {
            instance = new SmsVerticleConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    JsonObject config;
    
    public SmsVerticleConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("sms");
        setInstances(1);
        setConfig(config);
    }
    
    public static SmsVerticleConfig getInstance() {
        return instance;
    }
    
    public JsonObject getInstanceConfig() {
        return config;
    }
}
