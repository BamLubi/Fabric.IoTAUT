<template>
	<div>
		<!-- 新增按钮 -->
		<el-button class="add-button" type="primary" icon="el-icon-plus" circle @click="showAddDevice=true"></el-button>
		<!-- 显示设备列表 -->
		<el-table :data="tableData" v-loading="tableLoading" border stripe highlight-current-row lazy max-height="550">
			<el-table-column fixed type="index" label="序号" width="50"></el-table-column>
			<el-table-column fixed prop="Key" label="设备ID" width="150" sortable></el-table-column>
			<el-table-column prop="Record.msp" label="所属组织" width="150" sortable></el-table-column>
			<el-table-column prop="Record.docType" label="设备类型" width="150" sortable></el-table-column>
			<el-table-column prop="Record.data" label="数据" width="100" sortable></el-table-column>
			<el-table-column prop="Record.unit" label="数据单位" width="100"></el-table-column>
			<el-table-column prop="Record.timestamp" label="时间戳" width="150" sortable></el-table-column>
			<el-table-column prop="Record.desc" label="描述" sortable></el-table-column>
			<el-table-column fixed="right" label="操作" width="250">
				<template slot-scope="scope">
					<el-button type="text" size="small" icon="el-icon-search" @click="getHis(scope.row.Key)">查看历史数据</el-button>
					<el-button type="text" size="small" icon="el-icon-edit" @click="modify(scope.row)">修改</el-button>
				</template>
			</el-table-column>
		</el-table>
		<!-- 显示设备历史内容 -->
		<el-drawer title="设备数据历史记录" :visible.sync="showDeviceHistory" direction="ltr" size="75%">
			<h3>{{ selectDevice }}</h3>
			<el-table :data="historyData" v-loading="historyLoading" border stripe highlight-current-row lazy max-height="500">
				<el-table-column fixed type="index" label="序号" width="50"></el-table-column>
				<el-table-column property="data" label="数据" width="100" sortable></el-table-column>
				<el-table-column property="unit" label="数据单位" width="100"></el-table-column>
				<el-table-column property="docType" label="设备类型" width="100"></el-table-column>
				<el-table-column property="timestamp" label="时间戳" width="200" sortable></el-table-column>
				<el-table-column property="desc" label="描述" width="200" sortable></el-table-column>
				<el-table-column property="txId" label="交易ID"></el-table-column>
			</el-table>
		</el-drawer>
		<!-- 新增设备 -->
		<el-drawer title="新增设备信息" :visible.sync="showAddDevice" direction="ltr" size="50%">
			<el-form :model="deviceData" label-position="left" label-width="auto">
				<el-form-item label="设备ID" required><el-input type="text" v-model="deviceData.senId" placeholder="以如下格式命名: 组织号-设备号" clearable></el-input></el-form-item>
				<el-form-item label="设备类型">
					<el-input type="text" v-model="deviceData.type" placeholder="设备类型包括: temperature, humidity, pressure..." clearable></el-input>
				</el-form-item>
				<el-form-item label="数据"><el-input type="text" v-model="deviceData.data" clearable></el-input></el-form-item>
				<el-form-item label="数据单位"><el-input type="text" v-model="deviceData.unit" placeholder="数据单位包括: C, %, MPa" clearable></el-input></el-form-item>
				<el-form-item label="描述"><el-input type="text" v-model="deviceData.desc" placeholder="请输入设备的描述信息" clearable></el-input></el-form-item>
			</el-form>
			<div>
				<el-button @click="showAddDevice=false">取 消</el-button>
				<el-button type="primary" @click="addDevice">确 定</el-button>
			</div>
		</el-drawer>
	</div>
</template>

<script>
export default {
	name: 'deviceData',
	data() {
		return {
			tableData: [
				{
					Key: '',
					Record: {
						docType: '',
						data: '',
						unit: '',
						timestamp: ':36:27.828Z',
						desc: ''
					}
				}
			],
			selectDevice: '',
			historyData: [
				{
					docType: '',
					data: '',
					unit: '',
					timestamp: '',
					txId: '',
					desc: ''
				}
			],
			deviceData: {
				senId: '',
				data: '',
				type: '',
				unit: '',
				desc: ''
			},
			showDeviceHistory: false,
			showAddDevice: false,
			tableLoading: true,
			historyLoading: true,
			addDeviceLoading: false
		};
	},
	methods: {
		/**
		 * 获取指定设备的历史数据
		 * @param {Object} row
		 */
		getHis(row) {
			// 设置设备名称
			this.selectDevice = row;
			this.historyLoading = true;
			this.showDeviceHistory = true;
			// 网络请求
			this.$axios
				.post(this.$store.state.url + '/query/senhis', {
					enrollmentId: this.$store.state.userName,
					senId: row
				})
				.then(res => {
					console.log(res.data);
					if (res.data.code == 200) {
						this.historyData = JSON.parse(JSON.stringify(res.data.data));
						for (let item of this.historyData) {
							// 时间戳设置
							let tmp = item.timestamp.replace('T', ' ');
							tmp = tmp.replace('Z', '');
							item.timestamp = tmp;
						}
						this.historyLoading = false;
					} else {
						this.$message.error('获取数据失败!');
					}
				})
				.catch(err => {
					this.$message.error('获取数据失败!');
				});
		},
		/**
		 * 修改设备数据
		 * @param {Object} row
		 */
		modify(row) {
			// 设置设备名称
			this.selectDevice = row.Key;
			// 网络请求
			this.$prompt('请输入设备数据,设备ID(' + row.Key + ')', '提示', {
				confirmButtonText: '提交',
				cancelButtonText: '取消',
				inputPlaceholder: row.Record.data
			})
				.then(({ value }) => {
					const loading = this.$loading({
						lock: true,
						text: '提交中...',
						spinner: 'el-icon-loading',
						background: 'rgba(0, 0, 0, 0.7)'
					});
					this.$axios
						.post(this.$store.state.url + '/updateSen', {
							enrollmentId: this.$store.state.userName,
							senId: row.Key,
							data: value
						})
						.then(res => {
							loading.close();
							if (res.data.code == 200) {
								this.$message.success('修改数据成功!');
								this.getDeviceData();
							} else {
								this.$message.error('修改数据失败!');
							}
						})
						.catch(err => {
							loading.close();
							this.$message.error('修改数据失败!');
						});
				})
				.catch(() => {
					this.$message({
						type: 'info',
						message: '取消输入'
					});
				});
		},
		/**
		 * 新增设备
		 */
		addDevice() {
			const loading = this.$loading({
				lock: true,
				text: '提交中...',
				spinner: 'el-icon-loading',
				background: 'rgba(0, 0, 0, 0.7)'
			});
			this.$axios.post(this.$store.state.url + '/addSen', {
				enrollmentId: this.$store.state.userName,
				senId: this.deviceData.senId,
				data: this.deviceData.data,
				type: this.deviceData.type,
				unit: this.deviceData.unit,
				desc: this.deviceData.desc
			}).then(res=>{
				console.log(res);
				loading.close();
				if (res.data.code == 200) {
					this.$message.success('新增设备成功!');
					this.getDeviceData();
					this.showAddDevice = false;
				} else {
					this.$message.error('新增设备失败!');
				}
			}).catch(err=>{
				loading.close();
				this.$message.error('新增设备失败,网络错误!');
			})
		},
		/**
		 * 获取设备数据列表
		 */
		getDeviceData() {
			this.tableLoading = true;
			// 获取设备数据
			this.$axios
				.post(this.$store.state.url + '/query/allsens', {
					enrollmentId: this.$store.state.userName
				})
				.then(res => {
					console.log(res.data);
					if (res.data.code == 200) {
						this.tableData = JSON.parse(JSON.stringify(res.data.data));
						for (let item of this.tableData) {
							// 时间戳设置
							let tmp = item.Record.timestamp.replace('T', ' ');
							tmp = tmp.replace('Z', '');
							item.Record.timestamp = tmp;
							// 新增所属机构
							item.Record.msp = item.Key.split('-')[0];
						}
						this.tableLoading = false;
					} else {
						this.$message.error('获取数据失败!');
					}
				})
				.catch(err => {
					this.$message.error('获取数据失败!');
				});
		}
	},
	created: function() {
		this.getDeviceData();
	}
};
</script>

<style scoped>
.add-button {
	position: fixed;
	bottom: 10%;
	right: 10%;
}
.el-drawer .el-form {
	margin: 2%;
}
</style>
