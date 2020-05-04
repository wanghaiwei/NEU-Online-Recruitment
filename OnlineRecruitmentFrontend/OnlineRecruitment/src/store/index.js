import Vue from 'vue'
import Vuex from 'vuex'
import auth from "./auth"
import createPersistedState from "vuex-persistedstate"

Vue.use(Vuex);

let store = new Vuex.Store({
    modules: {
        auth: auth,
    },
    plugins: [
        createPersistedState({
            key: 'OnlineRecruitment',
            storage: window.sessionStorage,
        })
    ]
});

export default store;