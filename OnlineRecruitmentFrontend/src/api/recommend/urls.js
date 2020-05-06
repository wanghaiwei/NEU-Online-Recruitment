import baseUrl from '../baseUrl'

const prefix = baseUrl + '/verify';

const phoneVerify = function () {
    return `${prefix}/phone/new`;
};

const mailVerify = function () {
    return `${prefix}/mail/new`;
};

export default {
    phoneVerify,
    mailVerify,
}
