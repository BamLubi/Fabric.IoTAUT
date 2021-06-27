/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { Gateway, Wallets } = require('fabric-network');

var config = require('../config')
var R = require("../../utils/R")

/**
 * 功能：
 *      使用 appUser 实体查询链码
 * 前提条件：
 *      执行 enrollAdmin.js
 *      执行 registerUser.js
 * 主要流程：
 *      1. 新建wallet文件系统来统一管理用户实体的身份信息，即私钥和证书
 *      2. 检查是否已经登录了 appUser 实体
 *      3. 新建 gateway 来连接 peer 节点
 *      4. 获取通道、链码
 *      5. 执行链码中方法
 *      6. 关闭 gateway
 * 
 * 链码中可以调用的方法：
 * queryCar transaction - requires 1 argument
 *      ex: ('queryCar', 'CAR4')
 * queryAllCars transaction - requires no arguments
 *      ex: ('queryAllCars')
 * 
 * @param {*} enrollmentId 实体ID
 * @param {*} queryName 方法名
 * @param {...any} [args] 参数(可选)
 */
async function query(enrollmentId, queryName, ...args) {
    try {
        // 1. 新建一个基于wallet的文件系统用于管理实体信息，即签名和证书等
        const wallet = await Wallets.newFileSystemWallet(config.walletPath);

        // 2. 检查是否已经登录了appUser用户，如果没有则退出
        const identity = await wallet.get(enrollmentId);
        if (!identity) {
            console.log(`An identity for the user ${enrollmentId} does not exist in the wallet`);
            return new R(400, '', `An identity for the user ${enrollmentId} does not exist in the wallet`);
        }

        // 3. 新建gateway来连接peer节点
        // TODO: 如何指定哪个peer？
        const gateway = new Gateway();
        await gateway.connect(config.ccp, { wallet, identity: enrollmentId, discovery: { enabled: true, asLocalhost: true } });

        // 4. 获取指定通道（智能合约部署的通道）
        const network = await gateway.getNetwork(config.channelName);

        // 5. 获取指定的链码
        const contract = network.getContract(config.ccName);

        // 6. 评估指定的链码中方法，适用于查询操操作，查询世界状态
        const result = await contract.evaluateTransaction(queryName, ...args);

        // 7. 关闭gateway
        await gateway.disconnect();

        // 8. 返回信息
        return new R(200, JSON.parse(result.toString()), `Transaction(${queryName}) has been evaluated`);
        
    } catch (error) {
        console.error(`Failed to evaluate transaction(${queryName}): ${error}`);
        return new R(400, '', `Failed to evaluate transaction(${queryName}): ${error}`);
    }
}

module.exports = query;