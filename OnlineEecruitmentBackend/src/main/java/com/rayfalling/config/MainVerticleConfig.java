package com.rayfalling.config;

import com.rayfalling.middleware.ConfigLoader;
import com.rayfalling.verticle.MainVerticle;
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

    public static MainVerticleConfig getInstance() {
        return instance;
    }

    private MainVerticleConfig() throws IOException {
        JsonObject config = ConfigLoader.configObject().getJsonObject("server");
        setInstances(config.getInteger("instance"));
        setConfig(config.getJsonObject("listen"));
    }
}
