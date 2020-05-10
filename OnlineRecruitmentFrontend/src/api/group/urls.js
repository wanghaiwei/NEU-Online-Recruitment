import baseUrl from '../baseUrl'

const prefix = baseUrl + '/group';

const allCategory = function () {
    return `${prefix}/category/all`;
};

const allInfo = function () {
    return `${prefix}/info/all`;
};

const create = function () {
    return `${prefix}/create`;
};

const search = function () {
    return `${prefix}/search`;
};

const follow = function () {
    return `${prefix}/follow`;
};

export default {
    create,
    search,
    follow,
    allInfo,
    allCategory,
}
