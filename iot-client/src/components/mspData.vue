<template>
	<div>
		<!-- 新增按钮 -->
		<el-button class="add-button" type="primary" icon="el-icon-plus" circle @click="showAddMSP=true"></el-button>
		<!-- 显示MSP列表 -->
		<el-table :data="tableData" v-loading="tableLoading" border stripe highlight-current-row lazy max-height="550">
			<el-table-column fixed type="index" label="序号" width="50"></el-table-column>
			<el-table-column fixed prop="mspId" label="组织ID" width="150" sortable></el-table-column>
			<el-table-column fixed prop="children" label="包含设备">
				<template slot-scope="scope">
					<el-tag v-for="(item, i) in scope.row.children">{{ item }}</el-tag>
				</template>
			</el-table-column>
			<el-table-column prop="desc" label="描述" width="200" sortable></el-table-column>
			<el-table-column prop="timestamp" label="时间戳" width="200" sortable></el-table-column>
		</el-table>
		<!-- 新增组织 -->
		<el-drawer title="新增设备信息" :visible.sync="showAddMSP" direction="ltr" size="50%">
			<el-form :model="mspData" label-position="left" label-width="auto">
				<el-form-item label="组织ID" required><el-input type="text" v-model="mspData.mspId" placeholder="以如下格式命名: org[数字]" clearable></el-input></el-form-item>
				<el-form-item label="包含传感器"><el-input type="text" v-model="mspData.children" placeholder="请至设备信息处新增传感器" readonly></el-input></el-form-item>
				<el-form-item label="描述"><el-input type="text" v-model="mspData.desc" placeholder="请输入组织的描述信息" clearable></el-input></el-form-item>
			</el-form>
			<div>
				<el-button @click="showAddMSP=false">取 消</el-button>
				<el-button type="primary" @click="addMSP">确 定</el-button>
			</div>
		</el-drawer>
	</div>
</template>

<script>
export default {
	name: 'mspData',
	data() {
		return {
			tableData: [
				{
					mspId: '',
					children: [],
					desc: '',
					timestamp: ''
				}
			],
			mspData: {
				mspId: '',
				children: '',
				desc: ''
			},
			tableLoading: true,
			showAddMSP: false,
		};
	},
	methods: {
		/**
		 * 新增组织
		 * childre一项在链码中赋值为数组
		 */
		addMSP() {
			const loading = this.$loading({
				lock: true,
				text: '提交中...',
				spinner: 'el-icon-loading',
				background: 'rgba(0, 0, 0, 0.7)'
			});
			this.$axios.post(this.$store.state.url + '/addOrg', {
				enrollmentId: this.$store.state.userName,
				mspId: this.mspData.mspId,
				children: this.mspData.children,
				desc: this.mspData.desc
			}).then(res=>{
				console.log(res);
				loading.close();
				if (res.data.code == 200) {
					this.$message.success('新增组织成功!');
					this.getMspData();
					this.showAddMSP = false;
				} else {
					this.$message.error('新增组织失败!');
				}
			}).catch(err=>{
				loading.close();
				this.$message.error('新增组织失败,网络错误!');
			})
		},
		/**
		 * 获取MSP信息
		 */
		getMspData() {
			this.tableLoading = true;
			// 获取设备数据
			this.$axios
				.post(this.$store.state.url + '/query/msps', {
					enrollmentId: this.$store.state.userName
				})
				.then(res => {
					console.log(res.data);
					this.tableLoading = false;
					if (res.data.code == 200) {
						this.tableData = JSON.parse(JSON.stringify(res.data.data));
						for (let item of this.tableData) {
							// 时间戳设置
							let tmp = item.timestamp.replace('T', ' ');
							tmp = tmp.replace('Z', '');
							item.timestamp = tmp;
						}
					} else {
						this.$message.error('获取数据失败!');
					}
				})
				.catch(err => {
					this.tableLoading = false;
					this.$message.error('获取数据失败!');
				});
		}
	},
	created: function() {
		this.getMspData();
	}
};
</script>

<style scoped>
.add-button {
	position: fixed;
	bottom: 10%;
	right: 10%;
}
.el-tag {
	margin-right: 10px;
}
</style>
