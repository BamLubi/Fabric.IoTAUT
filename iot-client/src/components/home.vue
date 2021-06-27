<template>
	<div class="home">
		<el-container style="height: 100%;">
			<!-- 页头 -->
			<el-header style="height: 10%;">
				<!-- 标题 -->
				<h1>基于区块链的物联网认证系统</h1>
				<!-- 右边工具栏 -->
				<div>
					<i class="el-icon-user-solid userName">{{ $store.state.userName }}</i>
					<!-- <i class="el-icon-switch-button logOut"></i> -->
					<el-button class="logOut" icon="el-icon-switch-button" circle @click="logOut"></el-button>
				</div>
			</el-header>
			<!-- 侧边栏、主体、页脚 -->
			<el-container style="height: 90%;">
				<!-- 侧边栏 -->
				<el-aside width="15%">
					<el-menu :default-active="active" @open="handleOpen" @close="handleClose">
						<!-- 网络概况 -->
						<router-link to="/home/network" tag="span">
							<el-menu-item index="1">
								<i class="el-icon-cpu"></i>
								<span slot="title">网络概况</span>
							</el-menu-item>
						</router-link>
						<!-- 区块数据 -->
						<el-submenu index="2">
							<!-- 目录标题 -->
							<template slot="title">
								<i class="el-icon-menu"></i>
								<span slot="title">区块数据</span>
							</template>
							<!-- 组织信息 -->
							<router-link to="/home/mspData" tag="span">
								<el-menu-item index="2-1"><span>组织信息</span></el-menu-item>
							</router-link>
							<!-- 传感器信息 -->
							<router-link to="/home/deviceData" tag="span">
								<el-menu-item index="2-2"><span>设备信息</span></el-menu-item>
							</router-link>
						</el-submenu>
						<!-- 用户设置 -->
						<router-link to="/home/setting" tag="span">
							<el-menu-item index="3">
								<i class="el-icon-setting"></i>
								<span>用户设置</span>
							</el-menu-item>
						</router-link>
					</el-menu>
				</el-aside>
				<!-- 主体、页脚 -->
				<el-container style="height: 100%;">
					<!-- 主体 -->
					<el-main style="height: 90%;"><router-view></router-view></el-main>
					<!-- 页脚 -->
					<el-footer style="height: 10%;"><div>@CopyRight 南京工业大学-计算机科学与技术学院-计算机科学与技术(嵌入式)-计软1701-陆于洋-1405170121</div></el-footer>
				</el-container>
			</el-container>
		</el-container>
	</div>
</template>

<script>
export default {
	name: 'home',
	data() {
		return {
			active: '1'
		};
	},
	methods: {
		handleOpen(key, keyPath) {
			console.log(key, keyPath);
		},
		handleClose(key, keyPath) {
			console.log(key, keyPath);
		},
		logOut() {
			this.$router.push('/');
		}
	},
	mounted: function() {
		// 如果没有信息,则重新登陆
		if (this.$store.state.userName == '') {
			this.$message.error('请先登录');
			this.$router.push('/login');
		}
		// 
		this.active = this.$route.name;
	}
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
a {
	text-decoraction: none;
}
.router-link-active {
	text-decoration: none;
}
.home {
	width: 100%;
	height: 100%;
}
.el-header {
	background-color: #0984e3;
	color: #fff;
	border-bottom: 1px solid #eaeaea;
	box-shadow: 0 0 30px #cac6c6;
	z-index: 999;
	display: flex;
	flex-direction: row;
	align-items: center;
	justify-content: center;
}
.el-header div {
	position: absolute;
	right: 5%;
	font-size: 18px;
}
.el-header div .logOut {
	color: red;
	margin-left: 10px;
	border: none;
}
.el-footer {
	display: flex;
	justify-content: center;
	align-items: center;
}
.el-aside {
}
.el-aside .el-menu {
	height: 100%;
}
.el-main {
	width: 100%;
	height: 100%;
	padding: 0px;
	margin: 0px;
}
</style>
