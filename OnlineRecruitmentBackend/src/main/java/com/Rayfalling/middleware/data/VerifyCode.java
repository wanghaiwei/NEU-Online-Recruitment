package com.Rayfalling.middleware.data;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Objects;
import java.util.Random;

public class VerifyCode {
    
    static VerifyCode instance = new VerifyCode();
    //hash map to record username & code
    HashMap<String, Code> codeMap = new HashMap<>();
    //random generate (class only 4 reduce memory use)
    Random randomGenerate = new Random(System.currentTimeMillis());
    //string builder (class only 4 reduce memory use)
    StringBuilder codeBuilder = new StringBuilder();
    
    private VerifyCode() {}
    
    public static VerifyCode getInstance() {
        return instance;
    }
    
    /**
     * 添加一条新的记录
     *
     * @param username 用户名（手机号）
     * @param code     验证码
     * @author Rayfalling
     */
    public boolean add(String username, String code) {
        if (codeMap.containsKey(username))
            return false;
        codeMap.put(username, new Code(code));
        return true;
    }
    
    /**
     * 添加一条新的记录
     *
     * @param username 用户名（手机号）
     * @param code     验证码
     * @author Rayfalling
     */
    public void addOrUpdate(String username, String code) {
        if (codeMap.containsKey(username)) {
            codeMap.replace(username, new Code(code));
        } else {
            codeMap.put(username, new Code(code));
        }
    }
    
    /**
     * 获取对应的Code
     *
     * @param username 用户名（手机号）
     * @author Rayfalling
     */
    public Code find(String username) {
        return codeMap.getOrDefault(username, null);
    }
    
    /**
     * 校验验证码是否正确
     * 如果正确则删除记录
     * 不正确则保留
     *
     * @param username 用户名（手机号）
     * @param code     验证码
     * @author Rayfalling
     */
    public boolean verityCode(String username, String code) {
        return codeMap.containsKey(username) && !codeMap.get(username).isExpired() && codeMap.get(username).code
                                                                                              .equals(code) && codeMap.remove(username, codeMap.get(username));
    }
    
    /**
     * 创建随机的验证码
     *
     * @author Rayfalling
     */
    public String generateAddCode(String username) {
        String code = generateCode();
        addOrUpdate(username, code);
        return codeBuilder.toString();
    }
    
    /**
     * 创建随机的验证码
     *
     * @author Rayfalling
     */
    public String generateCode() {
        codeBuilder.delete(0, codeBuilder.length());
        int length = Math.abs(randomGenerate.nextInt()) % 2 + 4;
        int[] res = randomGenerate.ints(length, 0, 9).toArray();
        for (int i : res) {
            codeBuilder.append(i);
        }
        return codeBuilder.toString();
    }
    
    /**
     * 设置验证码过期时间
     *
     * @param expireTime 过期时间{@link Timestamp}
     */
    public static void setCodeExpireTime(Timestamp expireTime) {
        Code.setExpireTime(expireTime);
    }
    
    /**
     * 设置验证码过期时间
     *
     * @param expireTime 过期时间{@link Long}
     */
    public static void setCodeExpireTime(Long expireTime) {
        Code.setExpireTime(new Timestamp(expireTime));
    }
    
    /**
     * inner class of code record
     *
     * @author Rayfalling
     */
    public static class Code {
        static Timestamp expireTime = new Timestamp(300000);
        Timestamp createTime;
        String code;
        
        Code(String code) {
            this.code = code;
            this.createTime = Timestamp.valueOf(LocalDateTime.now());
        }
        
        public static Timestamp getExpireTime() {
            return expireTime;
        }
        
        /**
         * 设置验证码过期时间
         *
         * @param expireTime 过期时间{@link Timestamp}
         */
        public static void setExpireTime(Timestamp expireTime) {
            Code.expireTime = expireTime;
        }
        
        /**
         * 判定验证码是否过期
         *
         * @author Rayfalling
         */
        public boolean isExpired() {
            return Timestamp.valueOf(LocalDateTime.now()).getTime() > createTime.getTime() + expireTime.getTime();
        }
        
        public String getCode() {
            return code;
        }
        
        public Timestamp getCreateTime() {
            return createTime;
        }
        
        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Code)) return false;
            Code code1 = (Code) o;
            return getCreateTime().equals(code1.getCreateTime()) &&
                   getCode().equals(code1.getCode());
        }
        
        @Override
        public int hashCode() {
            return Objects.hash(getCreateTime(), getCode());
        }
    }
}
