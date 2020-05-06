import baseUrl from '../baseUrl'

const prefix = baseUrl + '/position';

const allCategory = function () {
    return `${prefix}/category/all`;
};

const post = function () {
    return `${prefix}/post`;
};

const deletePosition = function () {
    return `${prefix}/delete`;
};

const search = function () {
    return `${prefix}/search`;
};

const favorite = function () {
    return `${prefix}/favorite`;
};

export default {
    post,
    search,
    favorite,
    allCategory,
    deletePosition,
}
