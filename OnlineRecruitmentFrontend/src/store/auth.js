let auth = {
    namespaced: true,
    state: {
        isLogin: false,
        current_user: "",
        current_user_avatar: "",
        nickname: "",
        token: "",
    },
    mutations: {
        changeLoginStatus(state, payload) {
            state.isLogin = payload.state;
            state.nickname = payload.nickname;
            state.current_user = payload.username;
            state.current_user_avatar = payload.avatar;
        },
        changeUserToken(state, payload) {
            state.token = payload
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
        },
        Avatar: state => {
            return state.current_user_avatar
        },
    }
};

export default auth;