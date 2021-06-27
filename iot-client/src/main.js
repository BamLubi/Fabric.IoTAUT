import Vue from 'vue'
import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'
import store from './store'
import router from './router'
import App from './App.vue'
import axios from 'axios'

Vue.config.productionTip = false;
Vue.use(ElementUI);
Vue.prototype.$axios = axios;

new Vue({
	el: '#app',
	render: h => h(App),
	store,
	router
});
