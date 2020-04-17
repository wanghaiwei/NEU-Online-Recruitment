package com.Rayfalling.middleware.Utils.sql;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.Utils.Common;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;


public class SqlQuery {
    //映射表
    static HashMap<String, String> SqlMap = new HashMap<String, String>();
    
    static {
        //todo add map for sql file
        SqlMap.put("Register", "auth/register.sql");
        SqlMap.put("Login", "auth/login.sql");
        SqlMap.put("SelectId", "auth/select_id.sql");
    }
    
    /**
     * 从本地资源加载sql查询语句
     */
    public static String getQuery(String name) {
        String path = SqlMap.get(name);
        InputStream inputStream = Common.LoadResource("sql/" + path);
        ByteArrayOutputStream result = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int length = 0;
        while (true) {
            try {
                if ((length = inputStream.read(buffer)) == -1) break;
            } catch (IOException e) {
                Shared.getLogger().error(e.getMessage());
                e.printStackTrace();
            }
            result.write(buffer, 0, length);
        }
        try {
            return result.toString(StandardCharsets.UTF_8.name());
        } catch (Exception e) {
            Shared.getLogger().error(e.getMessage());
            e.printStackTrace();
            return result.toString();
        }
    }
}