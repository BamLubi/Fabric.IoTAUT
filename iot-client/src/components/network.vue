<template>
	<div>
		<!-- 当前区块 -->
		<div>
			<el-divider content-position="left">区块信息</el-divider>
			<div class="selectBC">
				<el-form :model="BCData" abel-position="left" label-width="auto">
					<el-form-item label="区块号">
						<el-select v-model="selectBC" placeholder="请选择区块号" v-loading="BCHeightLoading">
							<el-option v-for="item in BCHeight" :key="item" :label="item" :value="item"></el-option>
						</el-select>
						<el-tag type="info" style="margin-left: 1%;">当前区块链高度: {{ BCHeight }}</el-tag>
					</el-form-item>
					<div v-loading="BCDataLoading" style="width: 50%;">
						<el-form-item label="当前区块数据部分Hash"><el-input type="text" v-model="BCData.data_hash" placeholder="请选择区块号" v-loading="" readonly></el-input></el-form-item>
						<el-form-item label="前一区块头部Hash"><el-input type="text" v-model="BCData.previous_hash" placeholder="请选择区块号" readonly></el-input></el-form-item>
					</div>
				</el-form>
			</div>
		</div>
		<!-- 节点信息 -->
		<div style="margin-top: 5%;">
			<el-divider content-position="left">节点信息</el-divider>
			<!-- 显示节点列表 -->
			<el-table :data="containerList" v-loading="containerListLoading" border stripe highlight-current-row lazy>
				<el-table-column fixed type="index" label="序号" width="50"></el-table-column>
				<el-table-column fixed prop="name" label="节点域名" sortable></el-table-column>
				<el-table-column prop="type" label="节点类型" width="150" sortable></el-table-column>
				<el-table-column prop="ip" label="IP地址" width="200" sortable></el-table-column>
				<el-table-column prop="mac" label="MAC地址" width="200" sortable></el-table-column>
				<el-table-column prop="desc" label="描述" width="200" sortable></el-table-column>
			</el-table>
		</div>
	</div>
</template>

<script>
export default {
	name: 'network',
	data() {
		return {
			BCHeight: 2,
			selectBC: '',
			BCData: {
				data_hash: '',
				previous_hash: ''
			},
			newestBCData: {},
			BCDataLoading: false,
			BCHeightLoading: true,
			containerList: [
				{
					name: '',
					ip: '',
					mac: '',
					type: ''
				}
			],
			containerListLoading: true
		};
	},
	watch: {
		selectBC: 'getBCData'
	},
	methods: {
		/**
		 * 获取区块数据
		 */
		getBCData() {
			this.BCDataLoading = true;
			if (this.selectBC == this.BCHeight) {
				this.BCData.data_hash = this.newestBCData.currentBlockHash;
				this.BCData.previous_hash = this.newestBCData.previousBlockHash;
				this.BCDataLoading = false;
			} else {
				this.$axios
					.post(this.$store.state.url + '/option/getBCBlock', {
						blockNum: this.selectBC,
						type: 'hash'
					})
					.then(res => {
						this.BCDataLoading = false;
						if (res.data.code == 200) {
							this.BCData = res.data.data;
						} else {
							console.log('获取区块Hash失败');
						}
					})
					.catch(err => {
						this.BCDataLoading = false;
						console.log('获取区块Hash失败');
					});
			}
		},
		/**
		 * 获取区块链当前高度
		 */
		getBCHeight() {
			this.BCHeightLoading = true;
			this.$axios
				.get(this.$store.state.url + '/option/getBCHeight')
				.then(res => {
					this.BCHeightLoading = false;
					if (res.data.code == 200) {
						this.BCHeight = res.data.data.height;
						this.newestBCData = res.data.data;
					} else {
						console.log('获取区块高度失败');
					}
				})
				.catch(err => {
					this.BCHeightLoading = false;
					console.log('获取区块高度失败');
				});
		},
		/**
		 * 获取节点信息
		 */
		getContainer() {
			this.containerListLoading = true;
			this.$axios
				.get(this.$store.state.url + '/option/getDocker')
				.then(res => {
					this.containerListLoading = false;
					if (res.data.code == 200) {
						this.containerList = res.data.data;
					} else {
						console.log('获取节点信息失败');
					}
				})
				.catch(err => {
					this.containerListLoading = false;
					console.log('获取节点信息失败');
				});
		}
	},
	created: function() {
		this.getBCHeight();
		this.getContainer();
	}
};
</script>

<style scoped>
h3 {
	text-align: left;
	margin-left: 10%;
}
.selectBC{
	text-align: left;
	padding: 1% 2% 0% 2%;
}
.el-table{
	margin-top: 2%;
}
.el-divider__text {
	font-size: 18px;
}
</style>
