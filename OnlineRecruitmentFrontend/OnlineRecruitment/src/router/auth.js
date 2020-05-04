let router = [{
    path: '/login',
    component: () => import(/* webpackChunkName: "Login" */ '@views/Auth/Login.vue'),
    meta: {
        title: "登陆"
    }
}, {
    path: '/forgotPwd',
    component: () => import(/* webpackChunkName: "ForgotPwd" */ '@views/Auth/ForgotPwd.vue'),
    meta: {
        title: "重置密码"
    }
}, {
    path: '/register',
    component: () => import(/* webpackChunkName: "Register" */ '@views/Auth/Register.vue'),
    meta: {
        title: "注册"
    }
}, {
    path: '/infoDetails',
    alias: '/register/info',
    component: () => import(/* webpackChunkName: "InfoDetails" */ '@views/Auth/InfoDetails.vue'),
    meta: {
        title: "完善信息"
    }
}];
export default router
