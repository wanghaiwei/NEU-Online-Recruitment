import baseUrl from '../baseUrl'

const prefix = baseUrl + '/recommend';

const list = function () {
    return `${prefix}/list`;
};

const record = function () {
    return `${prefix}/record`;
};

export default {
    list,
    record,
}
