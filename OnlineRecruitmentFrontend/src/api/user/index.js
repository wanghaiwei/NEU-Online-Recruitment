import http from '../index'
import urls from './urls'

function login(urlOption, data) {
    return http.post(urls.login({...urlOption}), data)
}

function register(urlOption, data) {
    return http.post(urls.register({...urlOption}), data)
}

function logout(urlOption, data) {
    return http.post(urls.logout({...urlOption}), data)
}

function userInfoUpdate(urlOption, data) {
    return http.post(urls.userInfoUpdate({...urlOption}), data)
}

function userAuthentication(urlOption, data) {
    return http.post(urls.userAuthentication({...urlOption}), data)
}

function passwordReset(urlOption, data) {
    return http.post(urls.passwordReset({...urlOption}), data)
}

function passwordUpdate(urlOption, data) {
    return http.post(urls.passwordUpdate({...urlOption}), data)
}

function userFollow(urlOption, data) {
    return http.post(urls.userFollow({...urlOption}), data)
}

function userReport(urlOption, data) {
    return http.post(urls.userReport({...urlOption}), data)
}

function userProfile(urlOption, data) {
    return http.post(urls.userProfile({...urlOption}), data)
}


export default {
    login,
    logout,
    register,
    userFollow,
    userReport,
    userProfile,
    passwordReset,
    userInfoUpdate,
    passwordUpdate,
    userAuthentication,
}
