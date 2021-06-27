#!/bin/bash

networkName=docker_iot

# 获取网络id
networkID=`docker network ls | grep ${networkName} | awk '{print $1}'`

# 获取网络参数
docker network inspect ${networkID}