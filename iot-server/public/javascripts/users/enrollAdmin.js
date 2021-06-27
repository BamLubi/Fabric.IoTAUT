/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const FabricCAServices = require('fabric-ca-client');
const { Wallets } = require('fabric-network');

var config = require('../config')
var R = require("../../utils/R")


/**
 * 功能：
 *      登录 admin 实体
 * 主要流程：
 *      1. 使用 FabricCAServices 创建 CA 客户端
 *      2. 新建 wallet 文件系统来统一管理用户实体的身份信息，即私钥和证书
 *      3. 使用 FabricCAServices.enroll 方法登录用户实体，并保存身份信息到 wallet 中
 * 
 * 这里的用户实体主要指 -> admin
 * connection-org1.json 配置文件很重要，在网络搭建中配置
 */
async function enrollAdmin() {
    try {
        // 1. 创建一个新的CA客户端来与CA节点通信
        const ca = new FabricCAServices(config.caUrl, {
            trustedRoots: config.caTLSCACerts,
            verify: false
        }, config.caName);

        // 2. 新建一个基于wallet的文件系统用于管理实体信息，即签名和证书等
        const wallet = await Wallets.newFileSystemWallet(config.walletPath);

        // 3. 检查是否已经登录了admin用户，如果有则退出
        const identity = await wallet.get('admin');
        if (identity) {
            console.log('An identity for the admin user "admin" already exists in the wallet');
            return new R(200, identity, 'An identity for the admin user "admin" already exists in the wallet');
        }

        // 4. 登录admin用户
        const enrollment = await ca.enroll({
            enrollmentID: 'admin',
            enrollmentSecret: 'adminpw'
        });

        // 5. 导入新的实体信息到wallet中
        const x509Identity = new config.makeX509Identity(enrollment);
        await wallet.put('admin', x509Identity);
        console.log('Successfully enrolled admin user "admin" and imported it into the wallet', x509Identity);

        // 6. 返回信息
        return new R(200, x509Identity, 'Successfully enrolled admin user "admin" and imported it into the wallet');
    } catch (error) {
        console.error(`Failed to enroll admin user "admin": ${error}`);
        return new R(400, '', `Failed to enroll admin user "admin": ${error}`);
    }
}

module.exports = enrollAdmin;