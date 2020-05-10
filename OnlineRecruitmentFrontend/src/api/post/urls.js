import baseUrl from '../baseUrl'

const prefix = baseUrl + '/post';

const all = function () {
    return `${prefix}/all`;
};

const newPost = function () {
    return `${prefix}/new`;
};

const deletePost = function () {
    return `${prefix}/delete`;
};

const like = function () {
    return `${prefix}/like`;
};

const comment = function () {
    return `${prefix}/comment`;
};

export default {
    all,
    newPost,
    deletePost,
    like,
    comment,
}
