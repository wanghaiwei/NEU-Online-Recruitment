import baseUrl from '../baseUrl'

const prefix = baseUrl + '/user';

const register = function () {
    return `${prefix}/register`;
};

const login = function () {
    return `${prefix}/login`;
};

const logout = function () {
    return `${prefix}/logout`;
};

const userInfoUpdate = function () {
    return `${prefix}/info/update`;
};

const userProfile = function () {
    return `${prefix}/profile`;
};

const passwordReset = function () {
    return `${prefix}/password/reset`;
};

const passwordUpdate = function () {
    return `${prefix}/password/update`;
};

const userAuthentication = function () {
    return `${prefix}/authentication`;
};

const userFollow = function () {
    return `${prefix}/follow`;
};

const userReport = function () {
    return `${prefix}/report`;
};
export default {
    login,
    logout,
    register,
    userFollow,
    userReport,
    userProfile,
    passwordReset,
    userInfoUpdate,
    passwordUpdate,
    userAuthentication,
}
