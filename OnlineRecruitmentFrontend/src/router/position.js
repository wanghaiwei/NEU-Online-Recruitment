let router = [
    {
        path: '/position',
        component: () => import(/* webpackChunkName: "Index" */ '../views/Index.vue'),
        children: [{
            path: '/',
            components: {
                main: () => import(/* webpackChunkName: "Index" */ '../components/Position/Search.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/Position/Sidebar.vue'),
            },
            meta: {
                keepAlive: true,
                title: "首页",
            },
        }],
        meta: {
            keepAlive: true,
            title: "首页",
        },
    }, {
        path: '/position/detail',
        component: () => import(/* webpackChunkName: "Index" */ '../views/Index.vue'),
        meta: {
            title: "职位详情"
        },
        children: [{
            path: '/',
            components: {
                main: () => import(/* webpackChunkName: "PositionDetail" */ '../components/Position/Detail.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/Position/Sidebar.vue'),
            }
        }],
    },
];
export default router
