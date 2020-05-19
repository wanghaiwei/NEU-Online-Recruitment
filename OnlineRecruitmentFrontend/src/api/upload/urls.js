import baseUrl from '../baseUrl'

const prefix = baseUrl + '/upload';

const upload = function () {
    return `${prefix}/upload/new`;
};

export default {
    upload,
}
