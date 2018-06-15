# aria2

## 项目介绍
Linux(debian8\centos7\ubantu16)一键安装Aria2 + Caddy + YAAW实现离线下载。

## 功能说明

1. 离线下载
2. 在线查看
3. 文件管理
 
## 环境要求

1. 支持Linux(debian8+\centos7+\ubantu16+)
2. 不支持32位系统


## 安装教程

### Centos用户
 yum -y install unzip
### 如果是Debian or Ubuntu用户
 apt-get install -y unzip
### 下面的命令通用，直接复制
 wget https://github.com/xyzbeta/aria2/archive/master.zip && unzip master.zip && cd aria2-master && chmod u+x *.sh && ./install_aria2.sh

## 相关命令
#### 运行/重启/停止/查看状态
 ./aria2.sh
#### 一键安装
 ./install_aria2.sh
#### 一键卸载
./uninstall.sh
#### Caddy server配置文件
 /data/aria2/caddy.conf
#### Aria2配置文件
 /data/aria2/aria2.conf
#### 离线下载目录
 /data/aria2/download
#### 日志目录
 /data/aria2/aria2.log
 /data/aria2/caddy.log

## 使用说明

1. xxxx
2. xxxx
3. xxxx

## 常见问题及注意事项


## 特别感谢

https://www.xiaoz.me
