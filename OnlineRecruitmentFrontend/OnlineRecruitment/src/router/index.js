import Vue from 'vue'
import Router from 'vue-router'
import browser from '../utils/browser'
import HistoryStack from '../utils/browser/historyStack'
import auth from "./auth";
import explore from "./explore";
import personal from "./personal";

Vue.use(Router);

Router.prototype.goBack = function () {
    this.isBack = true;
    this.back();
};

let router = new Router({
    mode: 'history',
    base: process.env.BASE_URL,
    routes: [
        {
            path: '/',
            component: () => import(/* webpackChunkName: "Index" */ '@views/Index.vue'),
            meta: {
                title: "首页"
            }
        }, {
            path: '/index',
            component: () => import(/* webpackChunkName: "Index" */ '@views/Index.vue'),
            meta: {
                title: "首页"
            }
        }, {
            path: '/feedback',
            component: () => import(/* webpackChunkName: "Feedback" */ '@views/Feedback/feedback.vue'),
            meta: {
                title: "在线反馈"
            }
        }, ...auth, ...explore, ...personal, {
            path: '*',
            redirect: '/404'
        }, {
            path: '/404',
            component: () => import(/* webpackChunkName: "404" */ '@/views/404page'),
            meta: {
                title: "404"
            }
        }
    ]
});

let beforePath = browser.UA.isMobile ? "/m" : "/";

/**
 * 判断是否为移动设备，若是，则跳转到移动端的路径
 */
router.beforeEach((to, from, next) => {
    //404 is global
    if (to.path === "/404") {
        next();
        return;
    }
    let path, should_redirect;
    if (router.app.$utils.browser.UA.isMobile) {
        [path, should_redirect] = to.path.indexOf('/m') === 0 ? [to.path, false] : ['/m' + to.path, true];
    } else {
        [path, should_redirect] = to.path.indexOf('/m') === 0 ? [to.path.replace('/m', ''), true] : [to.path, false]
    }
    if (to.meta.title) {
        document.title = to.meta.title
    }
    if (path.endsWith("/") && path.length > 2)
        path = path.substr(0, path.length - 1);
    // if (path.endsWith("/404"))
    //     path = "/404";
    if (should_redirect) next(path);
    else next();
});

router.afterEach((to, from) => {
    if (router.isBack) {
        HistoryStack.pop();
        router.isBack = false;
        router.transitionName = 'back';
    } else {
        HistoryStack.push(to.path);
        router.transitionName = 'forward';
    }
});

export default router
