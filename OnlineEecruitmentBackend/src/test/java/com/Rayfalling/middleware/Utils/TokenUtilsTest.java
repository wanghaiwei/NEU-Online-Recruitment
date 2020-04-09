package com.Rayfalling.middleware.Utils;

import com.Rayfalling.middleware.data.Token;
import org.junit.Test;

import static org.junit.Assert.*;

public class TokenUtilsTest {
    
    @Test
    public void testEncryptAndDecrypt() {
        Token encrypt = new Token("18866662222");
        String encryptedToken = TokenUtils.EncryptFromToken(encrypt, "kFG^%@#5(*@&^@#$");
        System.out.println(encryptedToken);
        Token decrypt = TokenUtils.Decrypt2Token(encryptedToken, "kFG^%@#5(*@&^@#$");
        assert decrypt.equals(encrypt);
    }
}