import Vue from 'vue'
import Router from 'vue-router'
import HistoryStack from '../utils/browser/historyStack'
import auth from "./auth";
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
            component: () => import(/* webpackChunkName: "Index" */ '../views/Index.vue'),
            meta: {
                title: "首页"
            }
        }, {
            path: '/index',
            component: () => import(/* webpackChunkName: "Index" */ '../views/Index.vue'),
            meta: {
                title: "职位列表"
            }
        }, ...auth, ...personal, {
            path: '*',
            redirect: '/404'
        }, {
            path: '/404',
            component: () => import(/* webpackChunkName: "404" */ '../views/404Page'),
            meta: {
                title: "404"
            }
        }
    ]
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
