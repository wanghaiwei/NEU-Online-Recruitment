package com.Rayfalling.middleware.data;

import org.junit.Test;

import static org.junit.Assert.*;

public class VerifyCodeTest {
    
    @Test
    public void testGenerateCode() {
        String code = VerifyCode.getInstance().generateCode();
        System.out.println(code);
        assert code.length() <= 6 && code.length() >= 4;
        String code1 = VerifyCode.getInstance().generateCode();
        System.out.println(code1);
        assert code1.length() <= 6 && code1.length() >= 4;
    }
}