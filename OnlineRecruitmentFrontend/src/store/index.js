import Vue from 'vue'
import Vuex from 'vuex'
import auth from "./auth"
import createPersistedState from "vuex-persistedstate"
import * as Cookies from "js-cookie";

Vue.use(Vuex);

let store = new Vuex.Store({
    modules: {
        auth: auth,
    },
    plugins: [
        createPersistedState({
            key: 'OnlineRecruitment',
            storage: {
                getItem: (key) => Cookies.get(key),
                setItem: (key, value) =>
                    Cookies.set(key, value, { expires: 3 * 24, secure: true }),
                removeItem: (key) => Cookies.remove(key),
            },
        })
    ]
});

export default store;