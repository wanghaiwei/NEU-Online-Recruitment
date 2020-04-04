package com.rayfalling.config;

import com.rayfalling.middleware.ConfigLoader;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.json.JsonObject;

import java.io.IOException;

public class DatabaseVerticleConfig extends DeploymentOptions {
    JsonObject config;

    private static DatabaseVerticleConfig instance;

    static {
        try {
            instance = new DatabaseVerticleConfig();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static DatabaseVerticleConfig getInstance() {
        return instance;
    }

    public DatabaseVerticleConfig() throws IOException {
        config = ConfigLoader.configObject().getJsonObject("database");
        setInstances(1);
        setConfig(config);
    }

    public JsonObject getInstanceConfig() {
        return config;
    }
}
