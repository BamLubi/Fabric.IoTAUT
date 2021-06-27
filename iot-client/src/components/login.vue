<template>
	<div id="login">
		<el-container class="el-container">
			<el-main>
				<el-form :model="loginForm" status-icon ref="loginForm" label-position="left" label-width="20%">
					<!-- 标题 -->
					<h3 class="title">基于区块链的物联网认证系统-客户端</h3>
					<!-- 输入框 -->
					<el-form-item prop="userName" label="用户名"><el-input type="text" v-model="loginForm.userName" auto-complete="off" placeholder="用户名"></el-input></el-form-item>
					<el-form-item prop="file" label="证书文件">
						<el-input type="file" v-model="loginForm.fileName" id="file" auto-complete="off" placeholder="文件" @change="selectFile">
							<el-button slot="append" icon="el-icon-document" @click="openFile">显示内容</el-button>
						</el-input>
					</el-form-item>
					<!-- 按钮 -->
					<el-form-item label-width="0px">
						<el-button style="width: 30%;margin-right: 10px;" type="primary" @click="login" :loading="isLogining">登录</el-button>
						<el-button style="width: 30%;" type="danger" @click="register">注册</el-button>
					</el-form-item>
				</el-form>
			</el-main>
			<el-footer><div>@CopyRight 南京工业大学-计算机科学与技术学院-计算机科学与技术(嵌入式)-计软1701-陆于洋-1405170121</div></el-footer>
		</el-container>
		<!-- 显示文件内容 -->
		<el-drawer title="文件内容" :visible.sync="showFileContent" direction="rtl" size="30%">
			<el-form :model="fileForm" abel-position="left" label-width="auto">
				<el-form-item prop="certificate" label="证书"><el-input type="textarea" :rows="5" v-model="fileForm.credentials.certificate" readonly></el-input></el-form-item>
				<el-form-item prop="privateKey" label="私钥"><el-input type="textarea" :rows="5" v-model="fileForm.credentials.privateKey" readonly></el-input></el-form-item>
				<el-form-item prop="mspId" label="组织ID"><el-input type="text" v-model="fileForm.mspId" readonly></el-input></el-form-item>
				<el-form-item prop="type" label="证书格式"><el-input type="text" v-model="fileForm.type" readonly></el-input></el-form-item>
			</el-form>
		</el-drawer>
	</div>
</template>

<script>
// import networkUtils from "../utils/network.js"

export default {
	name: 'login',
	data() {
		return {
			loginForm: {
				userName: 'admin',
				fileName: ''
			},
			fileForm: {
				credentials: {
					certificate: '',
					privateKey: ''
				},
				mspId: '',
				type: ''
			},
			showFileContent: false,
			isLogining: false,
		};
	},
	methods: {
		/**
		 * 登录
		 * @param {Object} event
		 */
		login(event) {
			this.isLogining = true;
			let param = {
				enrollmentId: this.loginForm.userName,
				enrollmentWallet: this.fileForm
			}
			console.log(param)
			this.$axios.post(this.$store.state.url+"/users/login", param).then(res=>{
				this.isLogining = false;
				if(res.data.code == 200){
					this.$message.success('登录成功');
					// 保存信息到全局
					this.$store.state.userName = this.loginForm.userName;
					this.$store.state.userCTF = this.fileForm;
					// 跳转页面
					setTimeout(() => {
					    this.$router.push('/home/network');
					},2000);
				}else{
					this.$message.error('登录失败');
				}
			})
		},
		/**
		 * 注册
		 * @param {Object} event
		 */
		register(event) {
			var FileSaver = require('file-saver');
			let userName = '';
			this.$prompt('请输入用户名', '提示', {
				confirmButtonText: '确定',
				cancelButtonText: '取消'
			}).then(({ value }) => {
				userName = value;
				// 网络请求
				const loading = this.$loading({
					lock: true,
					text: '注册中...',
					spinner: 'el-icon-loading',
					background: 'rgba(0, 0, 0, 0.7)'
				});
				this.$axios.post(this.$store.state.url+"/users/register", {
					enrollmentId: value
				}).then(res=>{
					console.log(res)
					loading.close();
					// 成功则下载证书
					if(res.data.code == 200){
						let data = JSON.stringify(res.data.data);
						this.$confirm('点击确认下载证书文件(用户:'+value+')', '提示', {
							confirmButtonText: '确定',
							showCancelButton: false,
							closeOnClickModal: false,
							closeOnPressEscape: false,
							type: 'info'
						}).then(() => {
							// 保存文件
							var blob = new Blob([data], {type: "text/plain;charset=utf-8"});
							FileSaver.saveAs(blob, userName+".id");
							// 设置用户id
							this.loginForm.userName = userName;
						})
					}else{
						this.$message.error('注册失败');
					}
				})
			}).catch(() => {
				loading.close();
				this.$message.info('取消输入');
			});
		},
		/**
		 * 选择文件,并将文件内容赋值
		 */
		selectFile() {
			// 获取文件
			let resultFile = document.getElementById('file').files[0];
			// 获取内容
			if(this.loginForm.fileName!=''){
				var reader = new FileReader();
				reader.readAsText(resultFile);
				reader.onload = e => {
					let ans = JSON.parse(e.target.result);
					if(ans.credentials == '' || ans.credentials == undefined || ans.credentials == null){
						this.$message.error('文件格式不正确!');
						return;
					}else{
						this.fileForm = ans;
					}
				};
			}
		},
		/**
		 * 打开文件内
		 */
		openFile() {
			if(this.loginForm.fileName == '' || this.loginForm.file == ''){
				this.$message.error('请选择文件');
			}else{
				this.showFileContent = true;
			}
		}
	},
	created: function(){
		// 检测是否可以连接网络
		this.$axios.get(this.$store.state.url+"/", '').then(res=>{
			if(res.data.code == 200){
				this.$notify.success({
					title: '区块链网络',
					message: '已连上区块链网络!'
				});
			}else{
				this.$notify.error({
					title: '区块链网络',
					message: '无法连接区块链网络!'
				});
			}
		}).catch(err=>{
			this.$notify.error({
				title: '区块链网络',
				message: '无法连接区块链网络!'
			});
		})
	}
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
#login,
.el-container {
	width: 100%;
	height: 100%;
}
.el-footer {
	display: flex;
	justify-content: center;
	align-items: center;
	height: 20%;
}
.el-main {
	background-color: #ffffff;
	text-align: center;
	height: 80%;
	width: 100%;
	display: flex;
	justify-content: center;
	align-items: center;
}
.el-main .el-form {
	width: 30%;
	max-width: 50%;
	height: 40%;
	border-radius: 10px;
	padding: 2% 2% 1%;
	background: #fff;
	border: 1px solid #eaeaea;
	box-shadow: 0 0 25px #cac6c6;
}
.el-drawer .el-form {
	margin: 2%;
}
</style>
