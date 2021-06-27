#!/bin/bash
#
# 功能:
#   设置环境变量(切换用户)
#
# 示例:
#   ./envVar.sh [Flags]


# 1.导入外部脚本
. scripts/utils.sh

# 2.导出常用变量
## 是否启用TLS通信
export CORE_PEER_TLS_ENABLED=true
## 各节点的 CA 证书存放目录
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/njtech.com/orderers/orderer.njtech.com/msp/tlscacerts/tlsca.njtech.com-cert.pem
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.njtech.com/peers/peer0.org1.njtech.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.njtech.com/peers/peer0.org2.njtech.com/tls/ca.crt
## export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.njtech.com/peers/peer0.org3.njtech.com/tls/ca.crt

# 为 peer 节点设置环境变量
# @param $1 组织名称(org-name): 1,2,3
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  ## 根据不同组织设置环境变量
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.njtech.com/users/Admin@org1.njtech.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.njtech.com/users/Admin@org2.njtech.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
  else
    errorln "ORG Unknown"
  fi
  ## 是否展示当前环境变量
  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# 设置 cli 容器环境变量
setGlobalsCLI() {
  ## 设置环境变量为组织1
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_ADDRESS=peer0.org1.njtech.com:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_ADDRESS=peer0.org2.njtech.com:8051
  else
    errorln "ORG Unknown"
  fi
}

# 为链码操作设置节点连接参数
# 示例: parsePeerConnectionParameters $@
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## 设置 peer 节点地址
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    ## 设置 TLS 认证文件目录
    TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER0_ORG$1_CA")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # 向左移动参数列表
    shift
  done
  ## 删除字符串前面的空间
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

# 验证结果
verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

# 解析参数,使得在控制台可以直接使用内部函数
# 暂时只支持一个参数
if [[ $# -ne 0 ]] ; then
    key=$1
    case $key in
    -h | --help )
      println "Usage: "
      println "  ./envVar.sh \033[0;32m[Flags]\033[0m"
      println
      println "  Flags:"
      println "    -setGlobals [Flags] - 设置组织的环境变量"
      println "    -setGlobalsCLI [Flags] - 设置 cli 容器环境变量"
      println
      println " Examples:"
      println "  ./envVar.sh -setGlobals 1"
      println
      ;;
    -setGlobals )
      shift
      setGlobals $@
      ;;
    -setGlobalsCLI )
      shift
      setGlobalsCLI $@
      ;;
    * )
      # warnln "You have input wrong function name ($key) !!"
      ;;
    esac
fi