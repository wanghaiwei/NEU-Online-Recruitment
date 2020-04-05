package com.Rayfalling.config;

import com.Rayfalling.middleware.ConfigLoader;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class MainVerticleConfig extends DeploymentOptions {
    JsonObject config;

    private static MainVerticleConfig instance;

    static {
        try {
            instance = new MainVerticleConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static MainVerticleConfig getInstance() {
        return instance;
    }

    private MainVerticleConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("server");
        setInstances(config.getInteger("instance"));
        setConfig(config.getJsonObject("listen"));
    }

    public JsonObject getInstanceConfig() {
        return config;
    }
}
