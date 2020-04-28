package com.Rayfalling.verticle;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.data.VerifyCode;
import com.aliyuncs.CommonRequest;
import com.aliyuncs.DefaultAcsClient;
import com.aliyuncs.IAcsClient;
import com.aliyuncs.http.MethodType;
import com.aliyuncs.profile.DefaultProfile;
import io.reactivex.Single;
import io.vertx.core.Promise;
import io.vertx.core.json.JsonObject;
import io.vertx.reactivex.core.AbstractVerticle;
import io.vertx.reactivex.core.eventbus.MessageConsumer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jetbrains.annotations.NotNull;

@SuppressWarnings("ResultOfMethodCallIgnored")
public class SmsVerticle extends AbstractVerticle {
    private final Logger logger = LogManager.getLogger("Sms");
    DefaultProfile profile;
    IAcsClient client;
    VerifyCode verifyCode = VerifyCode.getInstance();
    String SignName = "职中小筑";
    CommonRequest request = new CommonRequest();
    MessageConsumer<JsonObject> messageConsumer;
    
    @Override
    public void start(Promise<Void> startPromise) {
        Single.just(true).flatMap(__ -> {
            if (config().containsKey("expireTime")) {
                VerifyCode.setCodeExpireTime(config().getLong("expireTime"));
            }
            if (config().containsKey("SignName")) {
                SignName = config().getString("SignName");
            }
            
            profile = DefaultProfile.getProfile("cn-hangzhou",
                    config().getString("accessKey"), config().getString("accessKeySecret"));
            client = new DefaultAcsClient(profile);
            
            request.setMethod(MethodType.POST);
            request.setDomain("dysmsapi.aliyuncs.com");
            request.setVersion("2017-05-25");
            request.setAction("SendSms");
            
            messageConsumer = Shared.getVertx().eventBus().<JsonObject>consumer("verify.phone").handler(msg -> {
                JsonObject body = msg.body();
                String code = verifyCode.generateAddCode(body.getString("phone"));
                request.putQueryParameter("RegionId", "cn-hangzhou");
                request.putQueryParameter("PhoneNumbers", body.getString("phone"));
                request.putQueryParameter("SignName", SignName);
                request.putQueryParameter("TemplateCode", "SMS_187755385");
                request.putQueryParameter("TemplateParam", new JsonObject().put("code", code).encode());
                try {
                    JsonObject response = new JsonObject(client.getCommonResponse(request).getData());
                    logger.info("Send phone number " + body.getString("phone") + " with code " + code + " succeed.");
                    msg.reply(new JsonObject().put("generateCode", code).mergeIn(response));
                } catch (Exception e) {
                    logger.error(e.getMessage());
                    e.printStackTrace();
                    msg.fail(-1, e.getMessage());
                }
            });
            
            messageConsumer.completionHandler(res -> {
                if (res.succeeded()) {
                    logger.info("Verify phone code handler register success");
                } else {
                    logger.error("Verify phone code handler registration failed!");
                }
            });
            return Single.just(messageConsumer);
        }).subscribe(res -> {
            startPromise.complete();
        }, startPromise::fail);
    }
    
    @Override
    public void stop(@NotNull Promise<Void> stopPromise) throws Exception {
        Single.just(messageConsumer).map(messageConsumer -> {
            messageConsumer.unregister();
            
            return Single.just(true);
        }).doOnSubscribe(res -> {
            logger.info("Starting unregister verify phone code handler...");
        }).doOnSuccess(res -> {
            logger.info("Verify phone code handler unregistered succeed!");
        }).subscribe(res -> {
            stopPromise.complete();
        }, stopPromise::fail);
    }
}
