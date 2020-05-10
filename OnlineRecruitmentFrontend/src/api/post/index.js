import http from '../index'
import urls from './urls'

function all(urlOption, data) {
    return http.post(urls.all({...urlOption}), data)
}

function newPost(urlOption, data) {
    return http.post(urls.newPost({...urlOption}), data)
}

function deletePost(urlOption, data) {
    return http.post(urls.deletePost({...urlOption}), data)
}

function like(urlOption, data) {
    return http.get(urls.like({...urlOption}), data)
}

function comment(urlOption, data) {
    return http.post(urls.comment({...urlOption}), data)
}

export default {
    all,
    newPost,
    deletePost,
    like,
    comment,
}
