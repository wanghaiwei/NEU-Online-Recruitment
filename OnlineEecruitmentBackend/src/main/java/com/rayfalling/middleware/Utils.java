package com.Rayfalling.middleware;

import com.Rayfalling.Shared;
import com.Rayfalling.StartUp;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.concurrent.Callable;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

public class Utils {
    static String Reg4Phone = "^[1](([3][0-9])|([4][5-9])|([5][0-3,5-9])|([6][5,6])|([7][0-8])|([8][0-9])|([9][1,8,9]))[0-9]{8}$";
    
    /**
     * @param <Obj> 传入对象
     *              高仿Kotlin apply()函数
     * @return <Obj>对象，执行失败返回null
     * @author Rayfalling
     */
    public static <Obj> Obj apply(Callable<Obj> callable) {
        try {
            return callable.call();
        } catch (Exception e) {
            Shared.getLogger().error(e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * @param phone 手机号
     * @return 是否匹配
     * @author Rayfalling
     */
    public static boolean isMobile(final String phone) {
        //来源手机号正则匹配
        Pattern pattern = Pattern.compile(Reg4Phone);
        Matcher m = pattern.matcher(phone);
        return m.matches();
    }
    
    
    /**
     * 从本地加载资源
     *
     * @param path 读取文件的路径
     * @return 返回文件的 {@code InputStream}
     */
    public static InputStream LoadResource(String path) {
        URL test = StartUp.class.getResource("");
        InputStream stream = null;
        if (test.getProtocol().equals("jar")) {
            stream = StartUp.class.getResourceAsStream("/resources/" + path);
        } else if (test.getProtocol().equals("file")) {
            URL resource = StartUp.class.getClassLoader().getResource(path);
            if (resource != null) {
                try {
                    stream = resource.openConnection().getInputStream();
                } catch (Exception e) {
                    Shared.getLogger().error(e.getMessage());
                    e.printStackTrace();
                }
            }
        }
        return stream;
    }
}
