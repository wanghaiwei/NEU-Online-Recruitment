let router = [
    {
        path: '/login',
        component: () => import(/* webpackChunkName: "Login" */ '../views/Auth/Login.vue'),
        meta: {
            title: "登录"
        }
    },
];
export default router
