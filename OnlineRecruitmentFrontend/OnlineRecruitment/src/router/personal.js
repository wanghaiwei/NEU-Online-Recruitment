let router = [{
    path: '/personal/:user',
    component: () => import(/* webpackChunkName: "Personal" */ '@views/Personal/PersonalPage.vue'),
    meta: {
        title: "个人资料"
    }
}];
export default router
