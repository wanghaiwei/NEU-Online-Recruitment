import http from '../index'
import urls from './urls'

function login(urlOption, data) {
    return http.post(urls.login({...urlOption}), data)
}

function logout(urlOption, data) {
    return http.post(urls.logout({...urlOption}), data)
}

function wechatLogin(urlOption, data) {
    return http.post(urls.wechatLogin({...urlOption}), data)
}

function passwordUpdate(urlOption, data) {
    return http.post(urls.passwordUpdate({...urlOption}), data)
}

function passwordReset(urlOption, data) {
    return http.post(urls.passwordReset({...urlOption}), data)
}

function passwordResetCaptcha(urlOption, data) {
    return http.post(urls.passwordResetCaptcha({...urlOption}), data)
}

function passwordResetSms(urlOption, data) {
    return http.post(urls.passwordResetSms({...urlOption}), data)
}

function passwordResetSmsValidate(urlOption, data) {
    return http.post(urls.passwordResetSmsValidate({...urlOption}), data)
}

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
