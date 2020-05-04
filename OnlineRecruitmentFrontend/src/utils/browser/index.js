import router from './jump'
import UA from './UA'
import history from './history'

export default {
    UA,
    route: {
        ...router,
        history
    }
}

