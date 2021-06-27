/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { Contract } = require('fabric-contract-api');

function MakeSensor(type, data, unit, timestamp, desc) {
    this.docType = type;
    this.data = data;
    this.unit = unit;
    this.timestamp = timestamp;// 不可以在链码中使用当前时间,会导致背书不一致
    this.desc = desc;
}

function MakeMSP(mspId, children, timestamp, desc) {
    this.mspId = mspId;
    this.children = children;
    this.desc = desc;
    this.timestamp = timestamp;
}

/**
 * FabIot智能合约,JavaScript版本
 */
class FabIot extends Contract {

    /**
     * 初始化账本
     * @param {*} ctx 
     */
    async initLedger(ctx) {
        console.info('============= START : Initialize Ledger ===========');
        // 录入组织信息
        let MSPs = [];
        MSPs.push(new MakeMSP('org1', ['org1-sen1', 'org1-sen2'], '2021-05-02T07:36:27.828Z', 'ORG1MSP'));
        MSPs.push(new MakeMSP('org2', ['org2-sen1', 'org2-sen2'], '2021-05-02T07:36:27.828Z', 'ORG2MSP'));
        console.log("Adding MSPs");
        await ctx.stub.putState('MSPs', Buffer.from(JSON.stringify(MSPs)));
        // 录入传感器数据
        const org1sen1 = new MakeSensor('temperature', '23.1', 'C', '2021-05-06T07:36:27.828Z', '组织1温度传感器');
        const org1sen2 = new MakeSensor('humidity', '62', '%', '2021-05-06T07:35:27.828Z', '组织1湿度传感器');
        const org2sen1 = new MakeSensor('temperature', '22.9', 'C', '2021-05-06T07:37:27.828Z', '组织2温度传感器');
        const org2sen2 = new MakeSensor('humidity', '58', '%', '2021-05-06T07:38:27.828Z', '组织2湿度传感器');
        console.log("Adding org1-sen1 org1-sen2 org2-sen1 org2-sen2");
        await ctx.stub.putState('org1-sen1', Buffer.from(JSON.stringify(org1sen1)));
        await ctx.stub.putState('org1-sen2', Buffer.from(JSON.stringify(org1sen2)));
        await ctx.stub.putState('org2-sen1', Buffer.from(JSON.stringify(org2sen1)));
        await ctx.stub.putState('org2-sen2', Buffer.from(JSON.stringify(org2sen2)));
        console.info('============= END : Initialize Ledger ===========');
    }

    /**
     * 查询指定字段信息,包括但不限于:
     * MSPs org1 org2 org1-sen1 org1-sen2
     * @param {*} ctx 
     * @param {*} key 字段键
     */
    async query(ctx, key) {
        // 从账本中获取数据
        const valueAsBytes = await ctx.stub.getState(key);
        if (!valueAsBytes || valueAsBytes.length === 0) {
            throw new Error(`${key} does not exist`);
        }
        console.log(key+": ", valueAsBytes.toString());
        return valueAsBytes.toString();
    }

    /**
     * 创建新的传感器
     * @param {*} ctx 
     * @param {*} senId 传感器id 
     * @param {*} type 类型
     * @param {*} data 数据
     * @param {*} unit 单位
     * @param {*} timestamp 时间戳
     * @param {*} desc 描述
     */
    async createSen(ctx, senId, type, data, unit, timestamp, desc) {
        // 是否已经存在该传感器
        const senAsBytes = await ctx.stub.getState(senId);
        if (!senAsBytes || senAsBytes.length === 0) {
            const sensor = new MakeSensor(type, data, unit, timestamp, desc);
            await ctx.stub.putState(senId, Buffer.from(JSON.stringify(sensor)));
            // 在MSPs中更改
            const MSPsAsBytes = await ctx.stub.getState('MSPs');
            let MSPs = JSON.parse(MSPsAsBytes.toString());
            let org = senId.split('-')[0];
            // 过滤并添加
            MSPs.filter((item) => {
                return item.mspId == org;
            })[0].children.push(senId);
            await ctx.stub.putState('MSPs', Buffer.from(JSON.stringify(MSPs)));
            console.log("Create Success!")
        }else{
            throw new Error(`${senId} already existed`);
        }
    }

    /**
     * 创建新的组织
     * @param {*} ctx 
     * @param {*} mspId 组织id
     * @param {*} children 包含的传感器编号
     * @param {*} timestamp 时间戳
     * @param {*} desc 描述
     */
    async createOrg(ctx, mspId, children, timestamp, desc) {
        // 获取MSPs
        const MSPsAsBytes = await ctx.stub.getState('MSPs');
        let MSPs = JSON.parse(MSPsAsBytes.toString());
        // 查看是否有该组织
        let flg = MSPs.filter((item) => {
            return item.mspId == mspId;
        });
        if(flg.length == 0){
            // 新增组织时,包含传感器始终为空
            children = [];
            const msp = new MakeMSP(mspId, children, timestamp, desc);
            MSPs.push(msp);
            await ctx.stub.putState('MSPs', Buffer.from(JSON.stringify(MSPs)));
            console.log("Create Success!")
        }else{
            // 有该组织
            throw new Error(`${mspId} already existed`);
        }
    }

    /**
     * 查询所有传感器数据
     * @param {*} ctx 
     */
    async queryAllSens(ctx) {
        const startKey = '';    // 开始键
        const endKey = '';      // 结束键
        const allResults = [];  // 结果列表
        // 遍历区块链所有键值对数据
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const reg = /org[0-9]+-sen[0-9]+/;  // 正则表达式过滤
            if(reg.test(key)){
                // 字节流解析为字符
                const strValue = Buffer.from(value).toString('utf8');
                let record;
                try {
                    record = JSON.parse(strValue);
                } catch (err) {
                    console.log(err);
                    record = strValue;
                }
                // 结果压入列表
                allResults.push({ Key: key, Record: record });
            }
        }
        return JSON.stringify(allResults);
    }

    /**
     * 查询传感器的历史信息
     * @param {*} ctx 
     * @param {*} senId 传感器id
     */
    async querySenHistory(ctx, senId) {
        let iterator = await ctx.stub.getHistoryForKey(senId);
        let results = [];
        let res = await iterator.next();
        while (!res.done) {
            if (res.value) {
                let obj = JSON.parse(res.value.value.toString('utf8'));
                obj["txId"] = res.value.txId;
                obj["txTimestamp"] = res.value.timestamp;
                results.push(obj);
            }
            res = await iterator.next();
        }
        await iterator.close();
        console.log(senId+" history data:", results);
        return JSON.stringify(results);
    }

    /**
     * 改变传感器数据
     * @param {*} ctx 
     * @param {*} senId 传感器id,即存储在账本中的key
     * @param {*} newData 传感器数据
     * @param {*} timestamp 时间戳
     */
    async updateSenData(ctx, senId, newData, timestamp) {
        // 从账本中获取传感器数据
        const senAsBytes = await ctx.stub.getState(senId);
        if (!senAsBytes || senAsBytes.length === 0) {
            throw new Error(`${senId} does not exist`);
        }
        // 修改
        const oldSensor = JSON.parse(senAsBytes.toString());
        console.log("old data: ", oldSensor);
        const newSensor = new MakeSensor(oldSensor.docType, newData, oldSensor.unit, timestamp, oldSensor.desc);
        console.log("new data: ", newSensor);
        await ctx.stub.putState(senId, Buffer.from(JSON.stringify(newSensor)));
        console.log("Update Success!")
    }
}

module.exports = FabIot;
