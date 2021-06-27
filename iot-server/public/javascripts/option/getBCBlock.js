/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

var R = require("../../utils/R")

function getBCHeight(res, blockNum, type) {
    var exec = require('child_process').exec;
    var cmdStr = "/bin/bash '/root/iot-network/api/getBCBlock.sh' " + blockNum + " -" + type;
    try {
        exec(cmdStr, function (err, stdout, stderr) {
            if (err) {
                res.send(new R(400, '', 'fail'));
            } else {
                res.send(new R(200, JSON.parse(stdout), 'success'));
            }
        });
    } catch (error) {
        console.log(error);
        res.send(new R(400, '', 'fail'));
    }
}

module.exports = getBCHeight;