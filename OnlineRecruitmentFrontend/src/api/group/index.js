import http from '../index'
import urls from './urls'

function create(urlOption, data) {
    return http.post(urls.create({...urlOption}), data)
}

function search(urlOption, data) {
    return http.post(urls.search({...urlOption}), data)
}

function follow(urlOption, data) {
    return http.post(urls.follow({...urlOption}), data)
}

function allInfo(urlOption, data) {
    return http.get(urls.allInfo({...urlOption}), data)
}

function allCategory(urlOption, data) {
    return http.get(urls.allCategory({...urlOption}), data)
}

export default {
    create,
    search,
    follow,
    allInfo,
    allCategory,
}
