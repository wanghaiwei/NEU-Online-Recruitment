import http from '../index'
import urls from './urls'

function list(urlOption, data) {
    return http.post(urls.list({...urlOption}), data)
}

function record(urlOption, data) {
    return http.post(urls.record({...urlOption}), data)
}

export default {
    list,
    record,
}
