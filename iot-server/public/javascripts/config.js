const { Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

// 区块链网络参数
const channelName = "mychannel";
const ccName = "mychaincode";

// 连接区块链网络参数
const ccpPath = path.resolve(__dirname, '..', 'connection.json');
const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));
const caInfo = ccp.certificateAuthorities['ca.org1.njtech.com'];
const caUrl = caInfo.url;       // 'https://localhost:7054'
const caName = caInfo.caName;   // 'ca-org1'
const caTLSCACerts = caInfo.tlsCACerts.pem;

// 钱包地址
const walletPath = path.join(__dirname, '..', 'wallet');

/**
 * 制作x509Identity实体信息
 * @param {Promise<FabricCAServices.IEnrollResponse>} enrollment 注册实体
 */
function makeX509Identity(enrollment) {
    this.credentials = {
        certificate: enrollment.certificate,
        privateKey: enrollment.key.toBytes(),
    };
    this.mspId = 'Org1MSP';
    this.type = 'X.509';
};

module.exports = {
    channelName,
    ccName,
    ccp,
    walletPath,
    caUrl,
    caName,
    caTLSCACerts,
    makeX509Identity
}