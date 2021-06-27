<template>
	<div style="text-align: left;">
		<!-- 当前用户 -->
		<div>
			<el-divider content-position="left">当前用户</el-divider>
			<el-form style="margin: 1% 2% 0% 2%;width: 50%;" :model="$store.state.userCTF" abel-position="left" label-width="auto">
				<el-form-item><el-tag type="danger">所有设置均不可改变, 否则将导致CA认证失败!</el-tag></el-form-item>
				<el-form-item label="用户名"><el-input type="text" v-model="$store.state.userName"></el-input></el-form-item>
				<el-form-item label="证书"><el-input type="textarea" :rows="5" v-model="$store.state.userCTF.credentials.certificate"></el-input></el-form-item>
				<el-form-item label="私钥"><el-input type="textarea" :rows="5" v-model="$store.state.userCTF.credentials.privateKey"></el-input></el-form-item>
				<el-form-item label="组织ID"><el-input type="text" v-model="$store.state.userCTF.mspId"></el-input></el-form-item>
				<el-form-item label="证书格式"><el-input type="text" v-model="$store.state.userCTF.type"></el-input></el-form-item>
			</el-form>
		</div>
		<!-- 当前服务器所有用户 -->
		<div>
			<el-divider content-position="left">当前服务器所有用户</el-divider>
			<el-row :gutter="5">
				<el-col v-for="(item, i) in allUser" :span="4">
					<el-tag>{{ item }}</el-tag>
				</el-col>
			</el-row>
		</div>
	</div>
</template>

<script>
export default {
	name: 'setting',
	data() {
		return {
			allUser: []
		};
	},
	methods: {
		getAllUser() {
			this.$axios
				.get(this.$store.state.url + '/users/userList')
				.then(res => {
					if (res.data.code == 200) {
						this.allUser = res.data.data;
					} else {
						console.log('获取所有用户失败');
					}
				})
				.catch(err => {
					console.log('获取所有用户失败');
				});
		}
	},
	created: function() {
		this.getAllUser();
	}
};
</script>

<style scoped>
.el-divider__text {
	font-size: 20px;
}
.el-row {
	text-align: center;
	width: 80%;
	margin-left: 10%;
	margin-right: 10%;
}
.el-col {
	border-radius: 4px;
	margin-bottom: 10px;
}
</style>
