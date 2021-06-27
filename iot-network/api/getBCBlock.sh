#!/bin/bash

nowPath=/root/iot-network

blockNum=$1
type=$2

# 配置变量
export CORE_PEER_TLS_ENABLED=true
## 各节点的 CA 证书存放目录
export ORDERER_CA=${nowPath}/organizations/ordererOrganizations/njtech.com/orderers/orderer.njtech.com/msp/tlscacerts/tlsca.njtech.com-cert.pem
export PEER0_ORG1_CA=${nowPath}/organizations/peerOrganizations/org1.njtech.com/peers/peer0.org1.njtech.com/tls/ca.crt
export PEER0_ORG2_CA=${nowPath}/organizations/peerOrganizations/org2.njtech.com/peers/peer0.org2.njtech.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
export CORE_PEER_MSPCONFIGPATH=${nowPath}/organizations/peerOrganizations/org1.njtech.com/users/Admin@org1.njtech.com/msp
export CORE_PEER_ADDRESS=localhost:7051

export FABRIC_CFG_PATH=${nowPath}/config

inputFilePath=${nowPath}/api/block/${blockNum}.block
outputFilePath=${nowPath}/api/block/${blockNum}.json

if [ ! -f outputFilePath ];then
    # 访问区块链
    peer channel fetch ${blockNum} ${inputFilePath} -c mychannel
    # 解码
    configtxlator proto_decode --input ${inputFilePath} --output=${outputFilePath} --type common.Block
fi

case $type in
    -hash )
        cat ${outputFilePath} | jq .header
        ;;
    -all )
        cat ${outputFilePath}
        ;;
	* )
		cat ${outputFilePath}
		;;
esac