import baseUrl from '../baseUrl'

const prefix = baseUrl + '/auth';

const login = function () {
    return `${prefix}/login`;
};

const wechatLogin = function () {
    return `${prefix}/login/wechat`;
};

const logout = function () {
    return `${prefix}/logout`;
};

const passwordUpdate = function () {
    return `${prefix}/password/update`;
};

const passwordResetCaptcha = function () {
    return `${prefix}/password/reset/captcha`;
};

const passwordResetSms = function () {
    return `${prefix}/password/reset/sms/send`;
};

const passwordResetSmsValidate = function () {
    return `${prefix}/password/reset/sms/validate`;
};

const passwordReset = function () {
    return `${prefix}/password/reset/action`;
};

export default {
    login,
    wechatLogin,
    logout,
    passwordUpdate,
    passwordReset,
    passwordResetCaptcha,
    passwordResetSms,
    passwordResetSmsValidate
}
