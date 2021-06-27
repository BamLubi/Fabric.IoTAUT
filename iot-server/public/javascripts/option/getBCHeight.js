/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

var R = require("../../utils/R")

function getBCHeight(res) {
    var exec = require('child_process').exec;
    var cmdStr = "/bin/bash '/root/iot-network/api/getBCHeight.sh'";
    try {
        exec(cmdStr, function (err, stdout, stderr) {
            if (err) {
                res.send(new R(400, '', 'fail'));
            } else {
                let ans = stdout.split(' ');
                if (ans[0] == 'Blockchain') {
                    res.send(new R(200, JSON.parse(ans[2]), 'success'));
                } else {
                    res.send(new R(400, '', stdout));
                }
            }
        });
    } catch (error) {
        console.log(error);
        res.send(new R(400, '', 'fail'));
    }
}

module.exports = getBCHeight;