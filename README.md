# Fabric.IoTAUT
> 基于区块链的物联网认证系统，使用Hyperledger Fabric 2.0 框架，实现区块链网络环境、服务器和客户端应用程序。

##  系统设计

本系统主要包括如下三大子模块：

1）区块链网络模块（iot-network）：模块主要实现区块链网络相关资产的部署和管理。资产包括节点、通道和智能合约等。并且此模块将向外部提供必要的接口，以用于访问、管理区块链网络中的资产。

2）服务端应用程序模块（iot-server）：此模块主要实现区块链网络操作接口的封装，并向服务请求者（如物联网设备、用户）提供相应的 API ，主要包括：实体注册、实体登录，区块数据存储、区块数据查询、区块链查询、节点信息查询等接口。

3）客户端应用程序模块（iot-client）：此模块主要实现可供用户直接操作本系统的可视化界面，使得用户可以模拟物联网设备接入区块链并操作区块链中资产。

系统的整体架构如下图所示：

<img src="img/系统图.png" alt="系统图" style="zoom: 50%;" />

## 使用流程

### 区块链网络模块(iot-network)

```shell
cd ./iot-network
# 1. 解压bin文件(fabric工具包)
# bin.tar.gz下载地址：
# 链接：https://pan.baidu.com/s/1K-PgsmqZkr4eKUlMdPGkEQ 
# 提取码：1tdp
$ tar -zxvf ./bin.tar.gz
# 2. 获取docker容器镜像
$ docker pull hyperledger/fabric-peer:2.2.2
$ docker pull hyperledger/fabric-orderer:2.2.2
$ docker pull hyperledger/fabric-ca:1.4.9
$ docker pull hyperledger/fabric-tools:2.2.2
$ docker pull hyperledger/fabric-ccenv:2.2.2
# 3. 使用--help查看相关指令
$ ./network.sh --help
# 4. 启动节点并创建通道
$ ./network.sh up createChannel -ca
# 5. 部署链码
$ ./network.sh deployCC
# 6. 停止fabric
$ ./network.sh down

## 除了使用自动化部署工具之外，也可以使用工具包自行部署
## 在./Fabric教程中有提及

## 需要修改的文件夹介绍
# ./chaincode -- 存放链码
# ./configtx -- 通道配置文件
# ./organizations/cryptogen -- 区块链组织架构
# ./docker -- docker节点配置

```

### 服务端应用程序模块(iot-server)

```shell
# Express项目
$ npm install
$ npm run serve
```

### 客户端应用程序模块(iot-client)

```shell
# Vue项目
$ npm install
$ npm run serve
```

## 参考网址

1.   fabric工具命令手册：http://cw.hubwiz.com/card/c/fabric-command-manual/1/1/27/

2.   fabric-sdk-for-nodejs：https://hyperledger.github.io/fabric-sdk-node
3.   区块链官方教程：https://hyperledger-fabric.readthedocs.io/zh_CN/release-2.2/
4.   B站fabric教程：https://www.bilibili.com/video/BV1DA41147vT

