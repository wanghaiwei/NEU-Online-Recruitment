package com.Rayfalling.middleware;

import com.Rayfalling.Shared;
import com.Rayfalling.StartUp;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.vertx.core.json.JsonObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
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
     * @throws IOException 文件不存在
     * @return 配置文件实例
     */
    private static File configFile() throws IOException {
        if (!configFileExternal.exists()) {
            Shared.getInstance().getLogger()
                  .info("Configuration file does not exist. Creating from default configuration.");
            //判定是jar运行还是IDE运行
            InputStream stream = Utils.LoadResource("config.json");

            //创建外部配置项
            if (!configFileExternal.exists()) {
                if (FileExt.CreateFileWithParentDir(configFileExternal)) {
                    FileOutputStream fileOutputStream = new FileOutputStream(configFileExternal);
                    if (stream != null) {
                        int available = stream.available();
                        byte[] buffer = new byte[available];
                        int read = stream.read(buffer);
                        if (read != available)
                            throw new IOException("Copy inner config failed");
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
     * @return JsonObject 配置项json对象
     */
    public static JsonObject configObject() throws IOException {
        return new JsonObject(new ObjectMapper().readTree(configFile()).toString());
    }
}
