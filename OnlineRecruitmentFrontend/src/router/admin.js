let router = [
    {
        path: '/admin',
        component: () => import(/* webpackChunkName: "Index" */ '../views/Admin.vue'),
        children: [{
            path: 'auth',
            components: {
                default: () => import(/* webpackChunkName: "Index" */ '../components/Admin/Authentication.vue'),
            },
            meta: {
                title: "身份认证申请",
            },
        }],
    },
];
export default router
