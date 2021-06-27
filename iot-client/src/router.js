import Vue from 'vue'
import VueRouter from 'vue-router'

Vue.use(VueRouter)

import home from '@/components/home'
import login from '@/components/login'
import setting from '@/components/setting'
import network from '@/components/network'
import deviceData from '@/components/deviceData'
import mspData from '@/components/mspData'

const routes = [{
	path: '/',
	redirect: 'login'
}, {
	path: '/login',
	component: login
}, {
	path: '/home',
	component: home,
	name: '1',
	children: [{
		path: '/home/setting',
		component: setting,
		name: '3'
	}, {
		path: '/home/network',
		component: network,
		name: '1'
	}, {
		path: '/home/deviceData',
		component: deviceData,
		name: '2-2'
	}, {
		path: '/home/mspData',
		component: mspData,
		name: '2-1'
	}]
}]

const router = new VueRouter({
	routes,
	mode: 'history'
});

export default router
