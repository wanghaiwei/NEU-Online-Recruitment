import http from '../index'
import urls from './urls'

function upload(urlOption, data) {
    return http.post(urls.upload({...urlOption}), data)
}

export default {
    upload,
}
