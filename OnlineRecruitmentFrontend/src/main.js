import Vue from 'vue'
import MainApp from './App.vue'
import router from './router'
import store from './store'
import globalFlags from './globalFlags/install'
import api from './api/install'
import utils from './utils/install'
import ViewUI from 'view-design';
import 'view-design/dist/styles/iview.css';

Vue.use(ViewUI);
Vue.use(globalFlags);
Vue.use(api);
Vue.use(utils);

Vue.config.productionTip = false;

const vm = new Vue({
    router,
    store,
    render: h => h(MainApp)
}).$mount('#app');
