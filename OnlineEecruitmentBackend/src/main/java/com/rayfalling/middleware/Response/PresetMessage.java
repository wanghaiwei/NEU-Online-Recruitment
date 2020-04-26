package com.Rayfalling.middleware.Response;

import com.Rayfalling.middleware.Utils.Common;
import io.vertx.core.json.JsonObject;

import java.util.concurrent.Callable;

public enum PresetMessage {
    /* 通用消息 */
    ERROR_FAILED(-100, "failed", "操作失败"),
    ERROR_UNKNOWN(),
    ERROR_UNIMPLEMENTED(-101, "unimplemented", "尚未实现"),
    ERROR_DATABASE(-102, "database exec failed", "数据库请求失败"),
    ERROR_AUTH_FAILED(-102, "auth failed", "权限校验失败"),
    SUCCESS(0, "ok", "操作成功"),
    
    /* 请求消息 */
    ERROR_REQUEST_PARAM(-201, "post param error", "参数错误"),
    ERROR_REQUEST_GET_PARAM(-202, "get param error", "参数错误"),
    ERROR_REQUEST_JSON(-203, "invalid json", "非法请求"),
    ERROR_REQUEST_JSON_PARAM(-204, "invalid json param", "参数错误"),
    
    /* 文件请求 */
    ERROR_FILE_NOT_FOUND(-501, "file not found", "文件未找到"),
    ERROR_UPLOAD_FAILED(-502, "upload error", "上传失败"),
    ERROR_FILE_ILLEGAL(-503, "illegal file", "非法文件类型"),
    
    /* Auth Message */
    ERROR_TOKEN_EXPIRED(-301, "token is expired", "会话过期"),
    ERROR_TOKEN_FAKED(-302, "token is faked", "无效会话"),
    
    /* 验证码相关 */
    ERROR_VERIFY_CODE_EXPIRED(40001, "Verify code is expired", "验证码过期"),
    ERROR_VERIFY_CODE_INCORRECT(40002, " Verify code incorrect", "验证码错误"),
    
    /* Defined Message */
    PHONE_REGISTERED_ERROR(50001, "phone number registered", "手机号已注册"),
    PASSWORD_FORMAT_ERROR(50002, "bad password format", "密码格式错误，密码需由8-16个字符组成，必须包含字母和数字"),
    PHONE_UNREGISTER_ERROR(50003, "phone number not registered", "手机号未注册"),
    INCORRECT_PASSWORD_ERROR(50004, "password incorrect", "密码错误"),
    VERIFY_CODE_ERROR(50005, "verification code error", "验证码错误"),
    USER_BLOCKED_ERROR(50006, "user blocked", "用户被封禁"),
    PREVIOUS_PASSWORD_INCORRECT_ERROR(50007, "old password incorrect", "旧密码输入错误"),
    NEW_PASSWORD_FORMAT_ERROR(50008, "bad new password format", "新密码格式错误"),
    DESCRIPTION_OVER_20_LIMIT_ERROR(50009, "description no more than 20 words", "简介在20字以内"),
    VERIFY_MAIL_FAILED_ERROR(50010, "email verification failed", "邮箱验证失败"),
    OUT_OF_POST_QUOTA_ERROR(50011, "position post insufficient quota", "职位发布额度不足，普通认证员工额度为1，HR额度为5"),
    DESCRIPTION_LESS_200_LIMIT_ERROR(50012, "description less than 200 words", "描述不能少于200字"),
    MODIFY_TIME_LESS_THAN_THREE_ERROR(50013, "can be modified every three days", "每三天可修改一次"),
    MODIFY_TIME_LESS_THAN_HALF_YEAR_ERROR(50014, "can be modified every 180 days", "每180天可修改一次"),
    CONTENT_DID_NOT_FIND_ERROR(50015, "failed to find content", "未能查找到对应内容"),
    USER_NOT_MEET_CREATE_LIMIT_ERROR(50016, "not meeting the criteria for creating circles", "用户不满足创建圈子条件"),
    DESCRIPTION_OVER_100_LIMIT_ERROR(50017, "description no more than 100 words", "描述不能多于100字"),
    OVER_MANAGE_ERROR(50018, "over management", "超额管理"),
    PHONE_FORMAT_ERROR(50019, "phone format incorrect", "手机号格式错误"),
    OLD_PASSWORD_INCORRECT_ERROR(50020, "old password format incorrect", "旧密码错误或用户不存在"),
    MAIL_FORMAT_ERROR(50021, "mail format incorrect", "邮箱格式错误"),
    ;
    
    int code;
    String message, description;
    
    PresetMessage(int code, String message, String description) {
        this.code = code;
        this.message = message;
        this.description = description;
    }
    
    PresetMessage() {
        this.code = -1;
        this.message = "unknown error";
        this.description = "未知错误";
    }
    
    public void apply(Callable<PresetMessage> fun) throws Exception {
        Common.apply(fun);
    }
    
    public String getMessage() {
        return message;
    }
    
    @Override
    public String toString() {
        return new JsonObject().put("code", this.code)
                               .put("message", this.message)
                               .put("description", this.description)
                               .encode();
    }
}
