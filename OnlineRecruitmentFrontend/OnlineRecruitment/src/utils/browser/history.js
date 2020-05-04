import HistoryStack from './historyStack';

let reject_status = false;
let callback_func = [];
let prevent_state = false;

let state = {
    prevent: true
};

let default_intercept_func = function (e) {
    if (reject_status && callback_func) {
        callback_func.forEach(func => func());
        prevent_state = false;
    }
};

const InterceptBackInit = function (prevent = false) {
    prevent_state = prevent;
    if (window.history && window.history.pushState) {
        window.addEventListener('popstate', default_intercept_func, false);//false阻止默认事件
    }
};

const InterceptBackDestroy = function () {
    if (window.history && window.history.pushState) {
        window.removeEventListener('popstate', default_intercept_func, false);
    }
};

const AddEvent = function (callback) {
    callback_func.push(callback);
    reject_status = true;
};

const RemoveEvent = function (callback) {
    callback_func.remove(callback_func.findIndex(item => item === callback));
    reject_status = false;
};

const RemoveAll = function () {
    callback_func = [];
    reject_status = false;
};

//阻止返回
const Prevent = function () {
    if (!prevent_state) {
        prevent_state = true;
        window.history.pushState(state, null, HistoryStack.top());
    }
};

//取消拦截
const Cancel = function () {
    prevent_state = false
};

export default {
    InterceptBackInit,
    RemoveAll,
    RemoveEvent,
    AddEvent,
    InterceptBackDestroy,
    Cancel,
    Prevent
}