import http from '../index'
import urls from './urls'

function phoneVerify(urlOption, data) {
    return http.post(urls.phoneVerify({...urlOption}), data)
}

function mailVerify(urlOption, data) {
    return http.post(urls.mailVerify({...urlOption}), data)
}

export default {
    phoneVerify,
    mailVerify,
}
