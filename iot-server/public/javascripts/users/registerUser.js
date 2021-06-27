/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');

var config = require('../config')
var R = require("../../utils/R")
var enrollAdmin = require("./enrollAdmin");

/**
 * 功能：
 *      使用 admin 实体新建 appUser 实体
 * 前提条件：
 *      执行 enrollAdmin.js
 * 主要流程：
 *      1. 使用 FabricCAServices 创建 CA 客户端
 *      2. 新建 wallet 文件系统来统一管理用户实体的身份信息，即私钥和证书
 *      3. 检查是否已经登录了 appUser 实体
 *      4. 检查是否已经登录了 admin 实体，因为只有 admin 可以新建用户
 *      5. 获取该钱包的实体注册列表
 *      6. 注册、登录、并导入到 wallet 中去
 * 
 * @param {String} enrollmentID 实体ID
 * @param {String} affiliation 所属机构
 * @param {String} role 角色
 */
async function register(enrollmentID, affiliation, role) {
    try {
        // 1. 创建一个新的CA客户端来与CA节点通信
        const ca = new FabricCAServices(config.caUrl);

        // 2. 新建一个基于wallet的文件系统用于管理实体信息，即签名和证书等
        const wallet = await Wallets.newFileSystemWallet(config.walletPath);

        // 3. 检查是否已经登录了appUser用户，如果有则退出
        const userIdentity = await wallet.get(enrollmentID);
        if (userIdentity) {
            console.log(`An identity for the user ${enrollmentID} already exists in the wallet`);
            return new R(200, userIdentity, `An identity for the user ${enrollmentID} already exists in the wallet`);
        }

        // 4. 检查是否已经登录了admin用户，如果没有则退出。（因为注册用户的操作必须要有admin权限）
        let adminIdentity = await wallet.get('admin');
        if (!adminIdentity) {
            console.log('An identity for the admin user "admin" does not exist in the wallet');
            console.log('Enrolling Admin....');
            await enrollAdmin();
            console.log('Enroll Admin Success!');
            adminIdentity = await wallet.get('admin');
        }

        // 5. 获取该钱包的实体注册提供者列表，并找到admin用户
        const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
        const adminUser = await provider.getUserContext(adminIdentity, 'admin');

        // 6. 注册用户实体,返回的是一串密码，该密码也可以自定义
        const secret = await ca.register({
            affiliation: affiliation,
            enrollmentID: enrollmentID,
            role: role
        }, adminUser);

        // 7. 登录用户实体,获得登录的私钥和证书
        // 密码只用作向CA节点认证
        const enrollment = await ca.enroll({
            enrollmentID: enrollmentID,
            enrollmentSecret: secret
        });

        // 8. 导入新的实体信息到wallet中
        const x509Identity = new config.makeX509Identity(enrollment);
        await wallet.put(enrollmentID, x509Identity);
        console.log(`Successfully registered and enrolled admin user ${enrollmentID} and imported it into the wallet`, x509Identity);

        // 9. 返回信息
        var ans = JSON.parse(JSON.stringify(x509Identity));
        ans.secret = secret;
        return new R(200, ans, `Successfully registered and enrolled admin user ${enrollmentID} and imported it into the wallet`)
    } catch (error) {
        console.error(`Failed to register user ${enrollmentID}: ${error}`);
        return new R(400, '', `Failed to register user ${enrollmentID}: ${error}`);
    }
}

module.exports = register;
