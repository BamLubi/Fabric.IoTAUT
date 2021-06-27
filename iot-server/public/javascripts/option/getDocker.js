/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

var R = require("../../utils/R")

function makeContainer(name, ip, mac) {
    this.name = name;
    this.ip = ip;
    this.mac = mac;
    if (name.search("ca") != -1) {
        this.type = "CA";
        this.desc = "认证节点";
    }else if(name.search("chaincode") != -1){
        this.type = "ChainCode";
        this.desc = "链码(智能合约)节点";
    }else if(name.search("peer") != -1){
        this.type = "Peer";
        this.desc = "主存储节点";
    }else if(name.search("cli") != -1){
        this.type = "Cli";
        this.desc = "客户端节点";
    }else if(name.search("orderer") != -1){
        this.type = "Orderer";
        this.desc = "排序节点";
    }else{
        this.type = "null";
        this.desc = "无";
    }
}

function dealStdout(src) {
    let ans = [];
    try {
        for (let item in src[0].Containers) {
            let tmp = src[0].Containers[item];
            ans.push(new makeContainer(tmp.Name, tmp.IPv4Address, tmp.MacAddress));
        }
        return ans;
    } catch (error) {
        return [];
    }
}

function getDocker(res) {
    var exec = require('child_process').exec;
    var cmdStr = "/bin/bash '/root/iot-network/api/getDocker.sh'";
    try {
        exec(cmdStr, function (err, stdout, stderr) {
            if (err) {
                res.send(new R(400, '', 'fail'));
            } else {
                console.log(stdout);
                let ans = dealStdout(JSON.parse(stdout))
                res.send(new R(200, ans, 'success'));
            }
        });
    } catch (error) {
        res.send(new R(400, '', 'fail'));
    }
}

module.exports = getDocker;