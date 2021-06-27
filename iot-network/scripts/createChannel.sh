#!/bin/bash
#
# 功能:
#   创建通道文件、创建通道、节点加入通道、创建锚节点
#
# 示例: 
#   ./createChannel.sh $(channel-name) $(delay) $(max-retry) $(verbose)
#   ./createChannel.sh
#   ./createChannel.sh iotchannel
#

# 1.导入外部脚本
## 设置环境变量用脚本  
. scripts/envVar.sh
## 设置输出控制台用
. scripts/utils.sh

# 2.获取调用本脚本时传入的参数
# @param $1 通道名称(channel-name): "mychannel"
# @param $2 延迟时间(delay): "3"
# @param $3 最大重试次数(max-retry): "5"
# @param $4 是否展示环境变量(verbose): "false"
CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

# 3.设置 FABRIC_CFG_PATH !!
FABRIC_CFG_PATH=${PWD}/configtx

# 4.如果不存在 channel-artifacts 目录, 则创建.
if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

# 创建通道文件, 命名为 ${CHANNEL_NAME}.tx
createChannelTx() {
	set -x
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

# 使用 peer 工具创建通道.which can used in the docker_cli_environment or just local.
createChannel() {
	## 设置全局环境为组织1!!
	setGlobals 1
	# 多次执行以防还没设置 leader 节点
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.njtech.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $BLOCKFILE --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# 组织加入通道
# @param $1 组织名称(org-name): 1,2
joinChannel() {
  ## 设置 FABRIC_CFG_PATH, 其中包含core.yaml
  FABRIC_CFG_PATH=$PWD/config/
  ## 设置环境变量, $1 为输入参数代表
  ORG=$1
  setGlobals $ORG
	## 有时加入通道需要时间, 因此需要多次尝试
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

# 设置锚节点
# @param $1 组织名称(org-name): 1,2
setAnchorPeer() {
  ORG=$1
  docker exec cli ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME 
}

##########
## MAIN ##
##########

# 5.创建通道文件
infoln "Generating channel create transaction '${CHANNEL_NAME}.tx'"
createChannelTx

# 6.设置 FABRIC_CFG_PATH, 其中包含运行环境必须的核心文件(core.yaml)!!
FABRIC_CFG_PATH=$PWD/config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

# 7.创建通道
infoln "Creating channel ${CHANNEL_NAME}"
createChannel
successln "Channel '$CHANNEL_NAME' created"

# 8.将所有节点加入通道
infoln "Joining org1 peer to the channel..."
joinChannel 1
infoln "Joining org2 peer to the channel..."
joinChannel 2

# 9.为每个节点添加锚节点
infoln "Setting anchor peer for org1..."
setAnchorPeer 1
infoln "Setting anchor peer for org2..."
setAnchorPeer 2

# 输出结束信息
successln "Channel '$CHANNEL_NAME' joined"
