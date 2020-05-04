let router = [{
    path: '/explore',
    component: () => import(/* webpackChunkName: "QuestionDiscord" */ '@views/QuestionAndAnswer/QuestionDiscord.vue'),
    meta: {
        title: "问答"
    }
}, {
    path: '/info',
    component: () => import(/* webpackChunkName: "InfoCenter" */ '@views/Info/InfoCenter.vue'),
    meta: {
        title: "信息"
    }
}, {
    path: '/info/new',
    component: () => import(/* webpackChunkName: "AddInfo" */ '@views/Info/AddInfo.vue'),
    meta: {
        title: "发布信息"
    }
}, {
    path: '/question/:questionId(\\d+)/answer/:answerId(\\d)',
    component: () => import(/* webpackChunkName: "AnswerDetail" */ '@views/QuestionAndAnswer/AnswerDetail.vue'),
    meta: {
        title: "回答详情"
    }
}, {
    path: '/question/:questionId(\\d+)',
    component: () => import(/* webpackChunkName: "AnswerDetail" */ '@views/QuestionAndAnswer/AnswerDetail.vue'),
    meta: {
        title: "回答详情"
    }
}, {
    path: '/question/new',
    component: () => import(/* webpackChunkName: "PutQuestion" */ '@views/QuestionAndAnswer/PutQuestion.vue'),
    meta: {
        title: "提问"
    }
}];
export default router