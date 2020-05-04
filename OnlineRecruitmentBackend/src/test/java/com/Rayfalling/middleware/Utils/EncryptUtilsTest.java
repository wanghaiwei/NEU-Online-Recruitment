package com.Rayfalling.middleware.Utils;

import com.Rayfalling.middleware.Utils.Security.EncryptUtils;
import com.Rayfalling.middleware.data.Token;
import org.junit.Test;

public class EncryptUtilsTest {
    
    @Test
    public void testEncryptAndDecrypt() {
        Token encrypt = new Token("18866662222");
        String encryptedToken = EncryptUtils.EncryptFromToken(encrypt, "kFG^%@#5(*@&^@#$");
        System.out.println(encryptedToken);
        Token decrypt = EncryptUtils.Decrypt2Token(encryptedToken, "kFG^%@#5(*@&^@#$");
        assert decrypt.equals(encrypt);
    }
}