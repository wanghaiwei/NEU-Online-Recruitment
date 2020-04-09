package com.Rayfalling.middleware.data;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.sql.Timestamp;
import java.time.LocalDateTime;

import static org.junit.Assert.*;

public class TokenTest {
    @Test
    public void testToken() throws InterruptedException {
        //create default Token
        Token token = new Token("13388886666");
        System.out.println(token.toString());
        assert !token.isExpired();
        token.setExpireTime(new Timestamp(4001).getTime());
        Thread.sleep(4000);
        assert token.isExpired();
        token.UpdateSession();
        assert !token.isExpired();
        
        //load from string
        String s = token.toString();
        Token token1 = new Token(s);
        assert token.equals(token1);
    }
}
