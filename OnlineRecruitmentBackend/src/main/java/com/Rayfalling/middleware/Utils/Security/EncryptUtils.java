package com.Rayfalling.middleware.Utils.Security;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.data.Token;
import org.jetbrains.annotations.Contract;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Objects;

public class EncryptUtils {
    
    static String key;
    
    /**
     * @param key key
     */
    public static void setKey(String key) {
        EncryptUtils.key = key;
    }
    
    /**
     * 加密Token, 用于认证用户身份
     *
     * @param key    salt for encrypt
     * @param source source string to encrypt
     * @return 加密后的Token
     * @author Rayfalling
     */
    @Nullable
    public static String EncryptFromString(String source, String key) {
        try {
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.ENCRYPT_MODE, getKey(key));
            byte[] p = source.getBytes(StandardCharsets.UTF_8);
            byte[] result = cipher.doFinal(p);
            return new String(Base64.getEncoder().encode(result), StandardCharsets.UTF_8);
        } catch (Exception e) {
            Shared.getLogger().fatal(e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * 加密Token, 用于认证用户身份
     *
     * @param source source string to encrypt
     * @return 加密后的Token
     * @author Rayfalling
     */
    public static String EncryptFromString(String source) {
        return EncryptFromString(source, key);
    }
    
    /**
     * 加密Token, 用于认证用户身份
     *
     * @param token token to encrypt
     * @return 加密后的Token
     * @author Rayfalling
     */
    public static String EncryptFromToken(@NotNull Token token) {
        return EncryptFromString(token.toString(), key);
    }
    
    
    /**
     * 加密Token, 用于认证用户身份
     *
     * @param key   salt for encrypt
     * @param token token to encrypt
     * @return 加密后的Token
     * @author Rayfalling
     */
    public static String EncryptFromToken(@NotNull Token token, String key) {
        return EncryptFromString(token.toString(), key);
    }
    
    /**
     * 解密Token, 用于认证用户身份
     *
     * @param key    salt for decrypt
     * @param source source string to decrypt
     * @return 解密后的Token String
     * @author Rayfalling
     */
    @Nullable
    public static String Decrypt2String(String source, String key) {
        try {
            byte[] DecodeBase64 = Base64.getDecoder().decode(source);
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.DECRYPT_MODE, getKey(key));
            byte[] result = cipher.doFinal(DecodeBase64);
            return new String(result, StandardCharsets.UTF_8);
        } catch (Exception e) {
            Shared.getLogger().fatal(e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    @Nullable
    public static String Decrypt2String(String source) {
        return Decrypt2String(source, key);
    }
    
    /**
     * 解密Token, 用于认证用户身份
     *
     * @param key    salt for decrypt
     * @param source source string to decrypt
     * @return 解密后的Token
     * @author Rayfalling
     */
    @NotNull
    @Contract("_, _ -> new")
    public static Token Decrypt2Token(String source, String key) {
        return new Token(Objects.requireNonNull(Decrypt2String(source, key)));
    }
    
    
    /**
     * 解密Token, 用于认证用户身份
     *
     * @param source source string to decrypt
     * @return 解密后的Token
     * @author Rayfalling
     */
    @NotNull
    @Contract("_ -> new")
    public static Token Decrypt2Token(String source) {
        return new Token(Objects.requireNonNull(Decrypt2String(source, key)));
    }
    
    /**
     * @param key 需要创建的key
     */
    @Nullable
    private static Key getKey(String key) {
        try {
            SecureRandom random = SecureRandom.getInstance("SHA1PRNG");
            random.setSeed(key.getBytes());
            KeyGenerator gen = KeyGenerator.getInstance("AES");
            gen.init(256, random);
            return gen.generateKey();
        } catch (Exception e) {
            Shared.getLogger().fatal(e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
}
