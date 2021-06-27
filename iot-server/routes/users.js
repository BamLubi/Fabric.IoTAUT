var express = require('express');
var router = express.Router();

var R = require("../public/utils/R");
var enrollAdmin = require("../public/javascripts/users/enrollAdmin");
var register = require("../public/javascripts/users/registerUser");
var login = require("../public/javascripts/users/login");
var userList = require("../public/javascripts/users/userList");

// 测试输出用
router.get('/', function(req, res, next) {
  res.send(new R(200, '', 'Success'));
});

// 注册用户实体
// POST
router.post('/login', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let enrollmentWallet = req.body.enrollmentWallet;
  console.log(enrollmentWallet);
  let ans = await login(enrollmentId, enrollmentWallet);
  res.send(ans);
});

// 登录Admin, 基本上只作为工具函数, 确保本地有Admin的登录信息以创建用户
// GET
router.get('/enrollAdmin', async function(req, res, next) {
  let ans = await enrollAdmin();
  res.send(ans);
});

// 注册用户实体
// POST
router.post('/register', async function(req, res, next) {
  let enrollmentId = req.body.enrollmentId;
  let ans = await register(enrollmentId, 'org1.department1', 'client');
  res.send(ans);
});

// 获取当前服务器所有用户
// GET
router.get('/userList', async function(req, res, next) {
  let ans = await userList();
  res.send(ans);
});

module.exports = router;
