
var exec = require('child_process').exec;
var cmdStr = "/bin/bash '/root/iot-network/api/getBCHeight.sh'";
exec(cmdStr, function (err, stdout, stderr) {
    let ans = JSON.parse(stdout);
});