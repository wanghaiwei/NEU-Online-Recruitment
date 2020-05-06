import http from '../index'
import urls from './urls'

function post(urlOption, data) {
    return http.post(urls.post({...urlOption}), data)
}

function search(urlOption, data) {
    return http.post(urls.search({...urlOption}), data)
}

function favorite(urlOption, data) {
    return http.post(urls.favorite({...urlOption}), data)
}

function allCategory(urlOption, data) {
    return http.get(urls.allCategory({...urlOption}), data)
}

function deletePosition(urlOption, data) {
    return http.post(urls.deletePosition({...urlOption}), data)
}

export default {
    post,
    search,
    favorite,
    allCategory,
    deletePosition,
}
