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
 *      使用 appUser 实体执行事务
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
 * 链码中可以调用的事务：
 * createCar transaction - requires 5 argument
 *      ex: ('createCar', 'CAR12', 'Honda', 'Accord', 'Black', 'Tom')
 * changeCarOwner transaction - requires 2 args
 *      ex: ('changeCarOwner', 'CAR12', 'Dave')
 */
async function main(enrollmentId, transactionName, ...args) {
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
        const gateway = new Gateway();
        await gateway.connect(config.ccp, { wallet, identity: enrollmentId, discovery: { enabled: true, asLocalhost: true } });

        // 4. 获取指定通道（智能合约部署的通道）
        const network = await gateway.getNetwork(config.channelName);

        // 5. 获取指定的链码
        const contract = network.getContract(config.ccName);

        // 提交指定的事务
        await contract.submitTransaction(transactionName, ...args);

        // 7. 关闭gateway
        await gateway.disconnect();

        // 8. 返回信息
        return new R(200, '', `Transaction(${transactionName}) has been evaluated`);

    } catch (error) {
        console.error(`Failed to submit transaction(${transactionName}): ${error}`);
        return new R(400, '', `Failed to evaluate transaction(${transactionName}): ${error}`);
    }
}

/**
 * 更新传感器数据
 * @param {*} enrollmentId 实体ID
 * @param {*} senId 传感器ID
 * @param {*} data 数据
 */
async function updateSenData(enrollmentId, senId, data){
    let nowDate = new Date().toISOString();
    return await main(enrollmentId, 'updateSenData', senId, data, nowDate);
}

/**
 * 新增传感器
 * @param {*} enrollmentId 实体ID
 * @param {*} senId 传感器ID
 * @param {*} type 类型
 * @param {*} data 数据
 * @param {*} unit 单位
 */
async function createSen(enrollmentId, senId, type, data, unit, desc){
    let nowDate = new Date().toISOString();
    return await main(enrollmentId, 'createSen', senId, type, data, unit, nowDate, desc);
}

/**
 * 新增组织
 * @param {*} enrollmentId 实体ID
 * @param {*} mspId 组织ID
 * @param {*} children 包含传感器
 * @param {*} desc 描述
 * @returns 
 */
async function createOrg(enrollmentId, mspId, children, desc){
    let nowDate = new Date().toISOString();
    return await main(enrollmentId, 'createOrg', mspId, children, nowDate, desc);
}


module.exports = {
    updateSenData,
    createSen,
    createOrg
};
