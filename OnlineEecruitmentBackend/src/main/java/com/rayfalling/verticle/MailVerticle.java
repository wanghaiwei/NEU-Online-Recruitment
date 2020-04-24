package com.Rayfalling.verticle;

import com.Rayfalling.Shared;
import com.Rayfalling.middleware.data.VerifyCode;
import io.vertx.core.Promise;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.mail.MailConfig;
import io.vertx.ext.mail.MailMessage;
import io.vertx.reactivex.core.AbstractVerticle;
import io.vertx.reactivex.core.eventbus.MessageConsumer;
import io.vertx.reactivex.ext.mail.MailClient;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class MailVerticle extends AbstractVerticle {
    private final Logger logger = LogManager.getLogger("Mail");
    MessageConsumer<JsonObject> messageConsumer;
    MailConfig config = new MailConfig();
    MailClient mailClient;
    
    @Override
    public void start(Promise<Void> startPromise) {
        config.setHostname(config().getString("host"));
        config.setPort(config().getInteger("port"));
        config.setSsl(config().getBoolean("ssl"));
        config.setUsername(config().getString("user"));
        config.setPassword(config().getString("pass"));
        mailClient = MailClient.create(Shared.getVertx(), config);
        
        messageConsumer = Shared.getVertx().eventBus().<JsonObject>consumer("verify.mail").handler(msg -> {
            String code = VerifyCode.getInstance().generateAddCode(msg.body().getString("mail_to"));
            MailMessage message = new MailMessage();
            message.setFrom(config().getString("user"));
            message.setTo(msg.body().getString("mail_to"));
            message.setSubject("【职中小筑】邮箱验证");
            message.setText("【职中小筑】验证码：" + code);
            mailClient.sendMail(message, result -> {
                if (result.succeeded()) {
                    logger.info("Mail send to " + msg.body().getString("mail_to") + " success");
                    msg.reply(new JsonObject().put("generateCode", code).put("status", true));
                } else {
                    logger.error("Mail send to " + msg.body().getString("mail_to") + " failed");
                    logger.error(result.cause());
                    msg.fail(-1, "Send failed");
                }
            });
            
        });
        
        messageConsumer.completionHandler(res -> {
            if (res.succeeded()) {
                logger.info("Mail server handler register success");
            } else {
                logger.error("Mail server handler registration failed!");
            }
        });
    }
    
    @Override
    public void stop(Promise<Void> stopPromise) throws Exception {
        messageConsumer.unregister();
        logger.info("Verify phone code handler unregistered succeed!");
    }
}
