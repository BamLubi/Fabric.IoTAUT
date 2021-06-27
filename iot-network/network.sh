#!/bin/bash
#
# 本脚本启动了一个超级账本网络,用来测试智能合约以及本地应用.
# 网络组成如下:
#   两个组织,每个组织各有一个 peer 节点,各有一个 ca 节点.
#		全局有一个 orderer 节点.
# 用户也可以使用该脚本创建一个通道,并在上面部署链码.


# 导入工具包环境,也可以在全局自己定义.该工具包包含了运行环境必要的指令工具集.
export PATH=$PATH:${PWD}/bin
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

# 导入脚本工具集(用于向控制台输出信息),包含如下函数:
#  errorln successln infoln warnln
. scripts/utils.sh

# 功能: 获取容器ID(CONTAINER_IDS)并将容器删除.
# 被调用: 网络关闭时(./network.sh down)
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
	## 判断是否有容器,有则删除容器.
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    infoln "No containers available for deletion"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# 功能: 删除启动网络时创建的镜像.
# 被调用: 网络关闭时(./network.sh down)
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    infoln "No images available for deletion"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# 低版本的 fabric 与该测试网络不兼容,即第一代 fabric 网络
NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

# 功能: 检查镜像版本是否满足要求.
function checkPrereqs() {
  ## 检查是否克隆了 peer 工具包以及配置文件
  peer version > /dev/null 2>&1
  if [[ $? -ne 0 || ! -d "./config" ]]; then
    errorln "Peer binary and configuration files not found.."
    errorln
    errorln "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
    errorln "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
    exit 1
  fi
  ## 使用 fabric-tools 镜像来检查案例和二进制文件是否与 docker 镜像匹配
  LOCAL_VERSION=$(peer version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

  infoln "LOCAL_VERSION=$LOCAL_VERSION"
  infoln "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    warnln "Local fabric binaries and docker images are out of sync. This may cause problems."
  fi

  for UNSUPPORTED_VERSION in $NONWORKING_VERSIONS; do
    infoln "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      fatalln "Local Fabric binary version of $LOCAL_VERSION does not match the versions supported by the test network."
    fi
    infoln "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      fatalln "Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the test network."
    fi
  done

  ## 检查 fabric-ca ,只有当启用了 ca 作为认证节点时才对 ca 进行检查
  if [ "$CRYPTO" == "Certificate Authorities" ]; then
    fabric-ca-client version > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      errorln "fabric-ca-client binary not found.."
      errorln
      errorln "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
      errorln "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
      exit 1
    fi
		### 检查本地 fabric-ca-client 与 fabric-ca 镜像是否相匹配
    CA_LOCAL_VERSION=$(fabric-ca-client version | sed -ne 's/ Version: //p')
    CA_DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-ca:$CA_IMAGETAG fabric-ca-client version | sed -ne 's/ Version: //p' | head -1)
    infoln "CA_LOCAL_VERSION=$CA_LOCAL_VERSION"
    infoln "CA_DOCKER_IMAGE_VERSION=$CA_DOCKER_IMAGE_VERSION"
    if [ "$CA_LOCAL_VERSION" != "$CA_DOCKER_IMAGE_VERSION" ]; then
      warnln "Local fabric-ca binaries and docker images are out of sync. This may cause problems."
    fi
  fi
}

# 在启动网路之前,需要为每一个组织创建 crypto 文件(该文件定义了网络中的组织).
# 因为超级账本是一个被许可管理的区块链,网络中每一个节点及用户需要使用证书和私钥来对其行为进行签名和认证.
# 除此之外,每一个用户都要属于一个组织.
# 你可以使用 Cryptogen 工具(在上文的 bin 工具包中有)或者 Fabric-CA 工具来生成组织描述文件.
#
# Cryptogen 工具:
# 用来开发和测试,可以快速创建被超级账本网络所认可的证书和私钥.
# "organizations/cryptogen"目录中,提供了一些列对组织的配置文件.
# 并且该工具将在此目录生成组织描述文件.
#
# Fabric-CA 工具:
# 用来为每个组织生成有效的根证书文件.
# 本脚本使用 Docker-Compose 启动三个 CA 节点,分别为两个组织和一个排序节点.
# "organizations/fabric-ca"目录中提供了启动 CA 节点所需的配置文件.
# 在同一个目录中,"registerEnroll.sh"脚本使用 CA 客户端创建实体、证书、和 MSP 目录.

# 功能: 创建组织描述文件(可以使用 Cryptogen 工具或 Fabric-CA 工具)
# $CRYPTO='cryptogen' | 'Certificate Authorities'
# 这里将 crypto-config.yaml 拆分为三个部分(orderer,org1,org2),但是我们也可以写在一个文件中.
function createOrgs() {
  ## 如果已经创建了 peerOrganizations 和 ordererOrganizations,就删除
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  ## 使用 Cryptogen 创建
  if [ "$CRYPTO" == "cryptogen" ]; then
    which cryptogen
    if [ "$?" -ne 0 ]; then
      fatalln "cryptogen tool not found. exiting"
    fi
    infoln "Generating certificates using cryptogen tool"

    infoln "Creating Org1 Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Org2 Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Orderer Org Identities"

    set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

  fi

  ## 使用 Fabric-CA 创建
  if [ "$CRYPTO" == "Certificate Authorities" ]; then
    infoln "Generating certificates using Fabric CA"
    ### 先把CA节点启动起来
    IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA up -d 2>&1
		### 导入工具包,用于创建证书和私钥,该工具包下有如下三个方法
    ### createOrg1、createOrg2、createOrderer
    . organizations/fabric-ca/registerEnroll.sh

		while :
			do
				if [ ! -f "organizations/fabric-ca/org1/tls-cert.pem" ]; then
					sleep 1
				else
					break
				fi
			done

    infoln "Creating Org1 Identities"
    createOrg1

    infoln "Creating Org2 Identities"
    createOrg2

    infoln "Creating Orderer Org Identities"
    createOrderer

  fi
	### 为组织创建 CCP 文件
  infoln "Generating CCP files for Org1 and Org2"
  ./organizations/ccp-generate.sh
}

# 功能: 创建排序节点系统通道创始区块
function createConsortium() {
	## 判断是否有 configtxgen 工具
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found."
  fi

	## 区块文件不可命名为 orderer.genesis.block
	infoln "Generating Orderer Genesis block"
  set -x
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate orderer genesis block..."
  fi
}

# 功能: 使用 Docker-Compose 启动 peer 和 orderer 节点
function networkUp() {
  ## 1. 检查环境
  checkPrereqs
  ## 2. 生成组织资产
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
    createConsortium
  fi
	# 3. 启动节点
  COMPOSE_FILES="-f ${COMPOSE_FILE_BASE}"
  if [ "${DATABASE}" == "couchdb" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f ${COMPOSE_FILE_COUCH}"
  fi

  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

# 功能: 创建通道,并将组织1和组织2的 peer 节点加入通道,然后为每个组织更新锚节点文件
function createChannel() {
  ## 如果网络未启动,则启动网络
  if [ ! -d "organizations/peerOrganizations" ]; then
    infoln "Bringing up network"
    networkUp
  fi

	## 该脚本又一次使用了 Configtxgen 工具来生成通道文件和锚节点更新文件.
	## configtx.yaml 文件被挂载在了 cli 容器中,以便我们在容器中创建通道文件.
  scripts/createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE
}

# 功能: 在通道上部署智能合约
function deployCC() {
  scripts/deployCC.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE
  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode failed"
  fi
}

# 功能: 停止当前运行的网络
function networkDown() {
  # 停止容器
  docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    ### 清除链码容器
    clearContainers
    ### 清除镜像
    removeUnwantedImages
    ### 清除区块和证书文件
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
    ### 清除 CA 资产
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org1/msp organizations/fabric-ca/org1/tls-cert.pem organizations/fabric-ca/org1/ca-cert.pem organizations/fabric-ca/org1/IssuerPublicKey organizations/fabric-ca/org1/IssuerRevocationPublicKey organizations/fabric-ca/org1/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org2/msp organizations/fabric-ca/org2/tls-cert.pem organizations/fabric-ca/org2/ca-cert.pem organizations/fabric-ca/org2/IssuerPublicKey organizations/fabric-ca/org2/IssuerRevocationPublicKey organizations/fabric-ca/org2/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    ### 清除通道文件和链码包文件
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'
  fi
}

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# 生成组织描述文件工具,'cryptogen' | 'Certificate Authorities'
CRYPTO="cryptogen"
# 最大重试次数
MAX_RETRY=5
# 命令之间的间隔时间
CLI_DELAY=3
# 通道名称
CHANNEL_NAME="mychannel"
# 链码名称
CC_NAME="mychaincode"
# 链码目录
CC_SRC_PATH="./chaincode/fabiot"
# 背书策略
CC_END_POLICY="NA"
# collection configuration defaults to "NA"
CC_COLL_CONFIG="NA"
# 链码初始化是否开启,若填'NA'则不开启
CC_INIT_FCN="initLedger"
# 本网络的 docker 启动文件地址
COMPOSE_FILE_BASE=docker/docker-compose-iot-net.yaml
# couchdb 数据库的 docker 启动文件地址
COMPOSE_FILE_COUCH=docker/docker-compose-couch.yaml
# CA 的 docker 启动文件地址
COMPOSE_FILE_CA=docker/docker-compose-ca.yaml
# 组织3的 couchdb 数据库的 docker 启动文件地址
# COMPOSE_FILE_COUCH_ORG3=addOrg3/docker/docker-compose-couch-org3.yaml
# 组织3的 docker 启动文件地址
# COMPOSE_FILE_ORG3=addOrg3/docker/docker-compose-org3.yaml
# 链码默认语言
CC_SRC_LANGUAGE="javascript"
# 链码版本,可以自定义
CC_VERSION="1.0"
# Chaincode definition sequence
CC_SEQUENCE=1
# 默认镜像版本号
IMAGETAG="2.2.2"
# CA 镜像版本号
CA_IMAGETAG="1.4.9"
# 默认数据库,可以使用'couchdb'
DATABASE="leveldb"

# 解析命令参数
# 解析模式
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# 解析子功能 createChannel 
if [[ $# -ge 1 ]] ; then
  key="$1"
  if [[ "$key" == "createChannel" ]]; then
      export MODE="createChannel"
      shift
  fi
fi

# 解析标志位
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp $MODE
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -ccl )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION="$2"
    shift
    ;;
  -ccs )
    CC_SEQUENCE="$2"
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY="$2"
    shift
    ;;
  -cccg )
    CC_COLL_CONFIG="$2"
    shift
    ;;
  -cci )
    CC_INIT_FCN="$2"
    shift
    ;;
  -i )
    IMAGETAG="$2"
    shift
    ;;
  -cai )
    CA_IMAGETAG="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

# Are we generating crypto material with this command?
if [ ! -d "organizations/peerOrganizations" ]; then
  CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
  CRYPTO_MODE=""
fi

# Determine mode of operation and printing out what we asked for
if [ "$MODE" == "up" ]; then
  infoln "Starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}' ${CRYPTO_MODE}"
elif [ "$MODE" == "createChannel" ]; then
  infoln "Creating channel '${CHANNEL_NAME}'."
  infoln "If network is not up, starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE} ${CRYPTO_MODE}"
elif [ "$MODE" == "down" ]; then
  infoln "Stopping network"
elif [ "$MODE" == "restart" ]; then
  infoln "Restarting network"
elif [ "$MODE" == "deployCC" ]; then
  infoln "deploying chaincode on channel '${CHANNEL_NAME}'"
else
  printHelp
  exit 1
fi

if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "createChannel" ]; then
  createChannel
elif [ "${MODE}" == "deployCC" ]; then
  deployCC
elif [ "${MODE}" == "down" ]; then
  networkDown
else
  printHelp
  exit 1
fi
