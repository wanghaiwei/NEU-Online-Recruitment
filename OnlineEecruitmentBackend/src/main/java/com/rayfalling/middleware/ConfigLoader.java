package com.rayfalling.middleware;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rayfalling.Shared;
import com.rayfalling.StartUp;
import io.vertx.core.json.JsonObject;

import java.io.*;
import java.net.URL;
import java.util.Arrays;

public class ConfigLoader {
    /**
     * 外部配置文件。
     */
    private static File configFileExternal = new File("conf/config.json");

    /**
     * 外部配置文件不存在时，复制并使用内部配置文件；
     * 外部配置文件存在时，优先使用外部配置文件。
     */
    private static File configFile() throws IOException {
        if (!configFileExternal.exists()) {
            Shared.getInstance().getLogger()
                  .info("Configuration file does not exist. Creating from default configuration.");
            //判定是jar运行还是IDE运行
            URL test = StartUp.class.getResource("");
            InputStream stream = null;
            if (test.getProtocol().equals("jar")) {
                stream = StartUp.class.getClassLoader().getResourceAsStream("/resource/config.json");
            } else if (test.getProtocol().equals("file")) {
                URL resource = StartUp.class.getClassLoader().getResource("config.json");
                if (resource != null) {
                    stream = resource.openConnection().getInputStream();
                } else {
                    throw new IOException("Open inner config failed");
                }
            }

            if (!configFileExternal.exists()) {
                //TODO error here
                if (FileExt.CreateFileWithParentDir(configFileExternal)) {
                    FileOutputStream fileOutputStream = new FileOutputStream(configFileExternal);
                    if (stream != null) {
                        int available = stream.available();
                        byte[] buffer = new byte[available];
                        int read = stream.read(buffer);
                        if (read != available)
                            throw new IOException("Copy inner config failed");
                        System.out.println(Arrays.toString(buffer));
                        fileOutputStream.write(buffer);
                        fileOutputStream.flush();
                        fileOutputStream.close();
                    }
                } else {
                    throw new IOException("Copy inner config failed");
                }
            }
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
