package com.Rayfalling.middleware;

import com.Rayfalling.Shared;

import java.util.concurrent.Callable;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

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
            Shared.getInstance().getLogger().error(e.getMessage());
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
}
