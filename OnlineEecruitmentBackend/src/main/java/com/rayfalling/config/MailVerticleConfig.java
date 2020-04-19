package com.Rayfalling.config;

import com.Rayfalling.middleware.Utils.ConfigLoader;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class MailVerticleConfig extends DeploymentOptions {
    private static MailVerticleConfig instance;
    
    static {
        try {
            instance = new MailVerticleConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    JsonObject config;
    
    public MailVerticleConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("mail");
        setInstances(1);
        setConfig(config);
    }
    
    public static MailVerticleConfig getInstance() {
        return instance;
    }
    
    public JsonObject getInstanceConfig() {
        return config;
    }
}
