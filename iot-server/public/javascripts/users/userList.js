/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { Wallets } = require('fabric-network');

var config = require('../config')
var R = require("../../utils/R")

async function userList(){
    try {
        const wallet = await Wallets.newFileSystemWallet(config.walletPath);
        const ans = await wallet.list();
        return new R(200, ans, `Successfully get all user`);
    } catch (error) {
        console.error(`Failed to get all user: ${error}`);
        return new R(400, '', `Failed to get all user: ${error}`);
    }
}

module.exports = userList;