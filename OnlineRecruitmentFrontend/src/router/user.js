let router = [
    {
        path: '/user',
        component: () => import(/* webpackChunkName: "Index" */ '../views/Index.vue'),
        children: [{
            path: 'auth',
            components: {
                main: () => import(/* webpackChunkName: "Index" */ '../components/User/Authentication.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/User/Sidebar.vue'),
            },
            meta: {
                keepAlive: true,
                title: "提交身份认证",
            },
        }, {
            path: 'add/position',
            components: {
                main: () => import(/* webpackChunkName: "Index" */ '../components/User/PostPosition.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/User/Sidebar.vue'),
            },
            meta: {
                keepAlive: true,
                title: "提交身份认证",
            },
        }],
        meta: {
            keepAlive: true,
            title: "个人中心",
        },
    },
];
export default router
