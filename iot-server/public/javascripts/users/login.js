'use strict';

const { Wallets } = require('fabric-network');

var config = require('../config')
var R = require("../../utils/R")

/**
 * 登录
 * 本地必须有账户，获取的wallet数据与本地比较
 * @param {*} enrollmentId 实体id
 * @param {*} enrollmentWallet 实体钱包
 */
async function login(enrollmentId, enrollmentWallet){
    try {
        const wallet = await Wallets.newFileSystemWallet(config.walletPath);
        // 检查本地是否有账户
        const userIdentity = await wallet.get(enrollmentId);
        const srcCredentials = userIdentity.credentials;
        if (userIdentity) {
            let dst = enrollmentWallet.credentials;
            if(JSON.stringify(srcCredentials)==JSON.stringify(dst)){
                console.log('Wallet exist user, Login success!')
                return new R(200, '', `Wallet exist user ${enrollmentId}, login success!`);
            }else{
                console.log('Wallet exist user, Login failed!')
                return new R(400, '', `Wallet exist user ${enrollmentId}, Login failed!`);
            }
        }else{
            console.log('Wallet not exist user, Login failed!');
            return new R(400, '', `Wallet not exist user ${enrollmentId}, Login failed!`);
        }
    } catch (error) {
        console.log(error);
        return new R(400, '', `Failed to login ${enrollmentId}: ${error}`);
    }
}

module.exports = login;
