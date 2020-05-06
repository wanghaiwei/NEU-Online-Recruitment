import router from '../../router'
import scrollbar from '../scrollbar'

const jumpRouter = async function (path, params) {
    if (router && path) {
        if (params) {
            router.match(path).meta.params = params;
        }
        await router.push(path).catch(error => {
            if (error && error.name !== 'NavigationDuplicated')
                console.log("路由跳转失败" + error)
        }).finally(() => scrollbar.scrollTo(0))
    }
};

const goBack = async function () {
    router.goBack();
};

const fetchParam = async function (path) {
    if (router && path) {
        return router.match(path).meta.params;
    }
};

export default {jump: jumpRouter, goBack, fetchParam};