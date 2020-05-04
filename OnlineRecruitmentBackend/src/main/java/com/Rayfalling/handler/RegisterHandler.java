package com.Rayfalling.handler;

import com.Rayfalling.Shared;
import com.Rayfalling.handler.Recommend.RecommendHandler;
import io.reactivex.Single;

import java.util.concurrent.TimeUnit;

public class RegisterHandler {
    public static void Register() {
        RecommendHandler.RegisterRecommendTimer();
    }
}
