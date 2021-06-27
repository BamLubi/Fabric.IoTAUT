#!/bin/bash
#
# 功能:
#   部署链码、初始化链码、执行查询任务
#

# 1.导入外部脚本
source scripts/utils.sh
. scripts/envVar.sh

# 2.获取并设置参数
# @param $1 通道名称(channel-name): "mychannel"
# @param $2 链码名称(cc-name): "mychaincode"
# @param $3 链码源文件位置(cc-src-path): "./chaincode/fabiot"
# @param $4 链码语言(cc-src-language): "javascript"
# @param $5 链码版本(cc-version): "1.0"
# @param $6 链码(cc-sequence): 1
# @param $7 链码初始化方法(cc-init-fcn): "initLedger"
# @param $8 背书策略(cc-end-policy): "NA"
# @param $9 collection文件路径(cc-coll-config): "NA"
# @param $10 延迟时间(delay): "3"
# @param $11 最大重试次数(max-retry): "5"
# @param $12 是否展示环境变量(verbose): "false"
CHANNEL_NAME=${1:-"mychannel"}
CC_NAME=${2:-"mychaincode"}
CC_SRC_PATH=${3:-"./chaincode/fabiot"}
CC_SRC_LANGUAGE=${4:-"javascript"}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
CC_INIT_FCN=${7:-"initLedger"}
# CC_VERSION="1.2"
# CC_SEQUENCE="3"
# CC_INIT_FCN="NA"
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}

## 输出当前的参数
println "executing with the following"
println "- CHANNEL_NAME: ${C_GREEN}${CHANNEL_NAME}${C_RESET}"
println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
println "- CC_SRC_LANGUAGE: ${C_GREEN}${CC_SRC_LANGUAGE}${C_RESET}"
println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"
println "- CC_SEQUENCE: ${C_GREEN}${CC_SEQUENCE}${C_RESET}"
println "- CC_END_POLICY: ${C_GREEN}${CC_END_POLICY}${C_RESET}"
println "- CC_COLL_CONFIG: ${C_GREEN}${CC_COLL_CONFIG}${C_RESET}"
println "- CC_INIT_FCN: ${C_GREEN}${CC_INIT_FCN}${C_RESET}"
println "- DELAY: ${C_GREEN}${DELAY}${C_RESET}"
println "- MAX_RETRY: ${C_GREEN}${MAX_RETRY}${C_RESET}"
println "- VERBOSE: ${C_GREEN}${VERBOSE}${C_RESET}"

# 3.设置 FABRIC_CFG_PATH !!
FABRIC_CFG_PATH=$PWD/config/

# 4.检查部分环境变量是否为空, 若为空则报错
## 用户未提供链码名称
if [ -z "$CC_NAME" ] || [ "$CC_NAME" = "NA" ]; then
  fatalln "No chaincode name was provided."
## 用户未提供链码路径
elif [ -z "$CC_SRC_PATH" ] || [ "$CC_SRC_PATH" = "NA" ]; then
  fatalln "No chaincode path was provided."
## 用户未提供链码语言
elif [ -z "$CC_SRC_LANGUAGE" ] || [ "$CC_SRC_LANGUAGE" = "NA" ]; then
  fatalln "No chaincode language was provided."
## 确保链码路径有效
elif [ ! -d "$CC_SRC_PATH" ]; then
  fatalln "Path to chaincode does not exist. Please provide different path."
fi

# 5.打包链码前对不同的链码版本做准备
## 确保字段值小写
CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])
## 匹配不同版本
case $CC_SRC_LANGUAGE in
  go )
    CC_RUNTIME_LANGUAGE=golang
    ### 将链码路径压入目录栈, 并切换当前目录
    infoln "Vendoring Go dependencies at $CC_SRC_PATH"
    pushd $CC_SRC_PATH
    GO111MODULE=on go mod vendor
    popd
    successln "Finished vendoring Go dependencies"
    ;;
  java )
    CC_RUNTIME_LANGUAGE=java
    infoln "Compiling Java code..."
    ### 编译java文件
    pushd $CC_SRC_PATH
    ./gradlew installDist
    popd
    successln "Finished compiling Java code"
    CC_SRC_PATH=$CC_SRC_PATH/build/install/$CC_NAME
    ;;
  javascript )
    CC_RUNTIME_LANGUAGE=node
    ;;
  typescript )
    CC_RUNTIME_LANGUAGE=node
    ### 将 typescript 编译成 javascript
    infoln "Compiling TypeScript code into JavaScript..."
    pushd $CC_SRC_PATH
    npm install
    npm run build
    popd
    successln "Finished compiling TypeScript code into JavaScript"
    ;;
  * )
    fatalln "The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script. Supported chaincode languages are: go, java, javascript, and typescript"
    exit 1
    ;;
esac

# 6.是否需要初始化函数, 如果初始化函数名为NA, 则不需要初始化
INIT_REQUIRED="--init-required"
if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

# 7.是否设置背书策略
## --signature-policy "OR('Org1MSP.member','Org2MSP.member')"
if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

# 8.是否设置 collection 文件路径
if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi

# 打包链码
packageChaincode() {
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

# 在 peer 节点上安装链码
installChaincode() {
  ## 设置组织环境变量
  ORG=$1
  setGlobals $ORG
  ## 安装链码
  set -x
  peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.org${ORG} has failed"
  successln "Chaincode is installed on peer0.org${ORG}"
}

# 查询 peer 节点是否已经安装链码
queryInstalled() {
  ## 设置组织环境变量
  ORG=$1
  setGlobals $ORG
  ## 查询 peer 是否已经安装
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.org${ORG} has failed"
  successln "Query installed successful on peer0.org${ORG} on channel"
}

# 代表所在机构审批链码
approveForMyOrg() {
  ## 设置组织环境变量
  ORG=$1
  setGlobals $ORG
  ## 审批链码
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.njtech.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME'"
}

# 检查指定链码是否可以向通道提交
checkCommitReadiness() {
  ## 设置组织环境变量
  ORG=$1
  shift 1
  setGlobals $ORG
  ## 多次尝试检查链码是否可以提交
  infoln "Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to check the commit readiness of the chaincode definition on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=0
    for var in "$@"; do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    infoln "Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Check commit readiness result on peer0.org${ORG} is INVALID!"
  fi
}

# 向指定通道提交链码
commitChaincodeDefinition() {
  ## 获取 peer 节点的地址和 tls 地址, 生成 PEER_CONN_PARMS
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  ## 提交链码
  ## -o 后面是 orderer 节点地址
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.njtech.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# 查询通道上已经提交的链码
queryCommitted() {
  ## 设置组织环境变量
  ORG=$1
  setGlobals $ORG
  ## 设置期待结果
  EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
  ## 查询, 需要制定链码名称和通道
  infoln "Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID!"
  fi
}

# 初始化链码
chaincodeInvokeInit() {
  ## 获取 peer 节点的地址和 tls 地址, 生成 PEER_CONN_PARMS
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  ## 提交
  set -x
  # 设置函数名为初始化链码 initLedger
  fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
  infoln "invoke function call: ${fcn_call}"
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.njtech.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS --isInit -c ${fcn_call} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

# 执行链码中方法
chaincodeInvoke() {
  ## 获取 peer 节点的地址和 tls 地址, 生成 PEER_CONN_PARMS
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  ## 提交
  set -x
  # 设置函数名为初始化链码 initLedger
  fcn_call='{"function":"updateSenData","Args":["org1-sen1","25","2021-05-06T10:50:27.828Z"]}'
  infoln "invoke function call: ${fcn_call}"
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.njtech.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS -c ${fcn_call} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

# 获取并显示链码函数调用的背书结果
chaincodeQuery() {
  ## 设置组织环境变量
  ORG=$1
  setGlobals $ORG
  infoln "Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  ## 查询
  ## 指定链码方法为查询所有汽车
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["queryAllSens"]}' >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID!"
  fi
}

# 9.打包链码
packageChaincode
# 10.在所有 peer 节点上安装链码
infoln "Install chaincode on peer0.org1..."
installChaincode 1
infoln "Install chaincode on peer0.org2..."
installChaincode 2
# 11.查询在组织1上是否安装了链码
queryInstalled 1
# 12.代表组织1审批链码
approveForMyOrg 1
# 13.检查链码是否可以向通道提交
## 预期结果是组织1允许, 组织2不允许
checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": false"
checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": false"
# 14.代表组织2审批链码
approveForMyOrg 2
# 15.检查链码是否可以向通道提交
## 预期结果是组织1和组织2都允许
checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true"
# 16.向指定通道提交链码, 参数1,2用于背书
commitChaincodeDefinition 1 2
# 17.分别以组织1和组织2的身份, 查询通道上已经提交的链码
queryCommitted 1
queryCommitted 2
# 18.初始化链码
if [ "$CC_INIT_FCN" = "NA" ]; then
  infoln "Chaincode initialization is not required"
else
  chaincodeInvokeInit 1 2
fi
# 19.测试查询数据
infoln "Query All sensors in Org1"
chaincodeQuery 1
# 20.测试修改数据
# infoln "Update org1-sen1 data in Org1"
# chaincodeInvoke 1
# # 21.测试查询数据
# infoln "Query All sensors in Org1"
# chaincodeQuery 1

exit 0
