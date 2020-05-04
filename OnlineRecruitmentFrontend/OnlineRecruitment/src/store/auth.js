let auth = {
    namespaced: true,
    state: {
        isLogin: false,
        current_user: "",
        token: "",
    },
    mutations: {
        changeLoginStatus(state, payload) {
            state.isLogin = payload.state;
            state.current_user = payload.username;
        },
        changeUserToken(state, payload) {
            state.user_avatar = payload.token
        }
    },
    actions: {
        changeLogin({commit, state}, payload) {
            commit('changeLoginStatus', payload)
        },
        changeToken({commit, state}, payload) {
            commit('changeUserToken', payload)
        }
    },
    getters: {
        LoginState: state => {
            return state.isLogin
        },
        IsCurrentUser: state => (user) => {
            return state.current_user === user
        },
        CurrentUser: state => {
            return state.current_user
        },
        Token: state => {
            return state.token
        }
    }
};

export default auth;