import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
	state:{
		url: "http://192.168.228.100:8080",
		test: 'HELLO_WORLD',
		userName: 'appUser',
		userCTF: {},
	},
	mutations: {
		
	},
	actions: {
		
	}
})