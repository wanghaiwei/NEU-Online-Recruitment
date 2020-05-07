let router = [
    {
        path: '/position/detail',
        component: () => import(/* webpackChunkName: "Index" */ '../views/Index.vue'),
        meta: {
            title: "职位详情"
        },
        children: [{
            path: '/',
            components: {
                main: () => import(/* webpackChunkName: "PositionDetail" */ '../components/Position/Detail.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/Sidebar.vue'),
            }
        }],
    },
];
export default router
