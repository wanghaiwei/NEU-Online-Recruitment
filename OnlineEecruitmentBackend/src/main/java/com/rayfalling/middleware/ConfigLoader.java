package com.rayfalling.middleware;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rayfalling.Shared;
import com.rayfalling.StartUp;
import io.vertx.core.json.JsonObject;

import java.io.*;
import java.net.URL;

public class ConfigLoader {
    /**
     * 外部配置文件。
     */
    private static File configFileExternal = new File("config.json");

    /**
     * 外部配置文件不存在时，复制并使用内部配置文件；
     * 外部配置文件存在时，优先使用外部配置文件。
     */
    private static File configFile() throws IOException {
        if (!configFileExternal.exists()) {
            Shared.getInstance().getLogger()
                  .info("Configuration file does not exist. Creating from default configuration.");
            URL resource = StartUp.class.getClassLoader().getResource("config.json");
            FileOutputStream fileOutputStream = new FileOutputStream ("config.json");
            if (resource != null) {
                byte[] buffer = resource.openConnection().getInputStream().readAllBytes();
                fileOutputStream.write(buffer);
                fileOutputStream.flush();
                fileOutputStream.close();
            } else {
                throw new IOException();
            }
            configFileExternal = new File("config.json");
        }
        return configFileExternal;
    }

    /**
     * 从配置文件中加载的配置对象。
     */
    public static JsonObject configObject() throws IOException {
        return new JsonObject(new ObjectMapper().readTree(configFile()).toString());
    }
}
