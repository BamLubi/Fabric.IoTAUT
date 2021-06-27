var express = require('express');
var router = express.Router();

var R = require("../public/utils/R");
var getBCHeight = require("../public/javascripts/option/getBCHeight");
var getBCBlock = require("../public/javascripts/option/getBCBlock");
var getDocker = require("../public/javascripts/option/getDocker");


router.get('/', function(req, res, next) {
  res.send(new R(200, '', 'GET'));
});

// 修改数据
// GET
router.get('/getBCHeight', function(req, res, next) {
  getBCHeight(res);
});

// 修改数据
// POST
router.post('/getBCBlock', function(req, res, next) {
  let blockNum = req.body.blockNum;
  let type = req.body.type;// ["hash", "all"]
  getBCBlock(res, blockNum, type);
});

// 获取docker网络参数
// GET
router.get('/getDocker', function(req, res, next) {
  getDocker(res);
});

module.exports = router;
