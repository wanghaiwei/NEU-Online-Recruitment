let router = [
    {
        path: '/group',
        component: () => import(/* webpackChunkName: "Index" */ '../views/Index.vue'),
        children: [{
            path: '/',
            components: {
                main: () => import(/* webpackChunkName: "Index" */ '../components/Group/Search.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/Group/Sidebar.vue'),
            },
            meta: {
                keepAlive: true,
                title: "圈子",
            },
        }, {
            path: 'new',
            components: {
                main: () => import(/* webpackChunkName: "Index" */ '../components/Group/Create.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/Group/Sidebar.vue'),
            },
            meta: {
                keepAlive: true,
                title: "创建圈子",
            },
        }],
    },
    {
        path: '/group/post',
        component: () => import(/* webpackChunkName: "Index" */ '../views/Index.vue'),
        children: [{
            path: '/',
            components: {
                main: () => import(/* webpackChunkName: "Index" */ '../components/Post/Detail.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/Post/Sidebar.vue'),
            },
            meta: {
                title: "动态",
            },
        }, {
            path: 'comment',
            components: {
                main: () => import(/* webpackChunkName: "Comment" */ '../components/Post/Comment.vue'),
                side: () => import(/* webpackChunkName: "Sidebar" */ '../components/Post/Sidebar.vue'),
            },
            meta: {
                title: "动态",
            },
        }],
    },
];
export default router
