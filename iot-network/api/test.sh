#!/bin/bash

blockNum=$1
channelName=mychannel

inputFilePath=${PWD}/api/block/${blockNum}.block
outputFilePath=${PWD}/api/block/${blockNum}.json

if [ ! -f outputFilePath ];then
    # peer 工具获取指定区块号的区块数据
    peer channel fetch ${blockNum} ${inputFilePath} -c ${channelName}
    # configtxlator 解码获取的区块数据
    configtxlator proto_decode --input ${inputFilePath} --output=${outputFilePath} --type common.Block
fi

