var express = require('express');
var router = express.Router();

var R = require("../public/utils/R");
var API = require("../public/javascripts/index/invoke");

/* GET home page. */
router.get('/', function(req, res, next) {
  res.send(new R(200, '', 'GET'));
});
router.post('/', function(req, res, next) {
  let param = req.body.param;
  res.send(new R(200, param, 'POST'));
});

// 修改数据
// POST
router.post('/updateSen', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let senId = req.body.senId; // 'org1-sen1'
  let data = req.body.data; // '25'
  let ans = await API.updateSenData(enrollmentId, senId, data);
  res.send(ans);
});

// 新增传感器
// POST
router.post('/addSen', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let senId = req.body.senId; // 'org1-sen1'
  let type = req.body.type; // 'temperature'
  let data = req.body.data; // '39'
  let unit = req.body.unit; // 'C'
  let desc = req.body.desc; // '描述'
  let ans = await API.createSen(enrollmentId, senId, type, data, unit, desc);
  res.send(ans);
});

// 新增组织
// POST
router.post('/addOrg', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let mspId = req.body.mspId; // 'org1'
  let children = req.body.children; // 包含传感器
  let desc = req.body.desc; // 描述
  let ans = await API.createOrg(enrollmentId, mspId, children, desc);
  res.send(ans);
});

module.exports = router;
