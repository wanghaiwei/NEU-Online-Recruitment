let router = [
    {
        path: '/login',
        component: () => import(/* webpackChunkName: "Login" */ '../views/Auth/Login.vue'),
        meta: {
            title: "登录"
        }
    }, {
        path: '/register',
        component: () => import(/* webpackChunkName: "Register" */ '../views/Auth/Register.vue'),
        meta: {
            title: "注册"
        }
    }, {
        path: '/resetPwd',
        component: () => import(/* webpackChunkName: "ResetPwd" */ '../views/Auth/ResetPwd.vue'),
        meta: {
            title: "重置密码"
        }
    },
];
export default router
