var express = require('express');
var router = express.Router();

var R = require("../public/utils/R");
var query = require("../public/javascripts/query/query");

// 自定义查询, 可以查询网络内任意变量
// POST
router.post('/', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let param = req.body.param;
  let ans = await query(enrollmentId, "query", param);
  res.send(ans);
});

// 查询所有传感器
// POST
router.post('/allsens', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let ans = await query(enrollmentId, "queryAllSens");
  res.send(ans);
});

// 查询MSPs
// POST
router.post('/msps', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let ans = await query(enrollmentId, "query", "MSPs");
  res.send(ans);
});

// 查询传感器的历史记录
// POST
router.post('/senhis', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let senId = req.body.senId;
  let ans = await query(enrollmentId, "querySenHistory", senId);
  res.send(ans);
});

module.exports = router;
