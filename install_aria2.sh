#!/bin/bash
#=================================================
#	System Required: CentOS 7+/Debian 8+/Ubuntu 16+
#	Description: 一键安装Aria2 + Yaaw
#	Version: 1.0
#	Author: XyzBeta
#	Blog: https://www.xyzbeta.com
#	Update: 2018/5/25
#=================================================

########################公共变量区##########################
#字体颜色
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Yellow_font_prefix="\033[33m" && Font_color_suffix="\033[0m"
#提示信息
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

##########################公共方法区########################
#判断用户是否具有root 权限
check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && exit 1
}

#判断系统发行版本
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

##########################业务方法区########################
#更新系统镜像源
function updateSource(){
	echo -e "${Info}修改${release}系统的镜像源为阿里云下载源"
	sys_date=`date "+%Y%m%d_%H%M%S"`
	if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		local debian_source="/etc/apt/sources.list"
		echo -e "${Info}保存系统默认镜像源文件"
		cp ${debian_source} ${debian_source}_${sys_date}
		/dev/null>${debian_source}
		cat>${debian_source}<<-EOF
			deb http://mirrors.aliyun.com/debian/ jessie main non-free contrib
			deb http://mirrors.aliyun.com/debian/ jessie-updates main non-free contrib
			deb http://mirrors.aliyun.com/debian/ jessie-backports main non-free contrib
			deb-src http://mirrors.aliyun.com/debian/ jessie main non-free contrib
			deb-src http://mirrors.aliyun.com/debian/ jessie-updates main non-free contrib
			deb-src http://mirrors.aliyun.com/debian/ jessie-backports main non-free contrib
			deb http://mirrors.aliyun.com/debian-security/ jessie/updates main non-free contrib
			deb-src http://mirrors.aliyun.com/debian-security/ jessie/updates main non-free contrib
			deb http://mirrors.aliyun.com/debian wheezy main contrib non-free
			deb-src http://mirrors.aliyun.com/debian wheezy main contrib non-free
			deb http://mirrors.aliyun.com/debian wheezy-updates main contrib non-free
			deb-src http://mirrors.aliyun.com/debian wheezy-updates main contrib non-free
			deb http://mirrors.aliyun.com/debian-security wheezy/updates main contrib non-free
			deb-src http://mirrors.aliyun.com/debian-security wheezy/updates main contrib non-free
		EOF
		echo -e "${Info}源替换完毕,开始进行系统更新"
		apt-get update
	elif [ "${release}" = "centos" ];then
		local centos_soure="/etc/yum.repos.d/CentOS-Base.repo"
		echo -e "${Info}保存系统默认镜像源文件"
		cp ${centos_soure} ${centos_soure}_${sys_date}
		rm -y ${centos_source}
		wget -O CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
		yum clean all
		yum makecache
	fi
}

#自动放行端口
function chk_firewall() {
	if [[ ${release} == "centos" ]]; then
		firewall-cmd --zone=public --add-port=6080/tcp --permanent
		firewall-cmd --zone=public --add-port=6800/tcp --permanent
		firewall-cmd --zone=public --add-port=51413/tcp --permanent
		firewall-cmd --reload
	fi
}

#aria2服务安装
function installaria2(){
	echo -e "${Info}开始安装aria2服务"
	if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		apt-get -y install curl
		apt-get -y install aria2
	elif [[ "${release}" == "centos" ]]; then
		yum -y install curl
		yum -y install epel-release
		yum -y install aria2
	fi
}

#Aria2设置
function setting(){
	mkdir -p /data/aria2
	mkdir -p /data/aria2/download
	touch /data/aria2/aria2.session
	cp aria2.conf caddy.conf aria2.sh /data/aria2
	read -p "${Info}设置用户名：" user
	read -p "${Info}设置密码：" pass
	read -p "${Info}设置连接口令" token
	sed -i "s/rpc-secret=/rpc-secret=${token}/g" /data/aria2/aria2.conf
	#sed -i "s/#rpc-user=/rpc-user=${user}/g" /data/aria2/aria2.conf
	#sed -i "s/#rpc-passwd=/rpc-passwd=${pass}/g" /data/aria2/aria2.conf
	#移动yaaw
	mv yaaw/* /data/aria2
	#移动caddy
	mv caddy/caddy.filemanager /usr/bin/caddy
	chmod +x /usr/bin/caddy
	#修改配置
	sed -i "s/username/${user}/g" /data/aria2/caddy.conf
	sed -i "s/password/${pass}/g" /data/aria2/caddy.conf
	#放行端口
	if [[ "${release}" == "centos" ]]; then
		chk_firewall
	fi
	#启动服务
	cd /data/aria2
	nohup aria2c --conf-path=/data/aria2/aria2.conf > /data/aria2/aria2.log 2>&1 &
	nohup caddy -conf="/data/aria2/caddy.conf" > /data/aria2/caddy.log 2>&1 &
	echo "------------------安装完成，请牢记以下信息。------------------"
	echo "${Info}访问地址：http://${osip}:6080"
	echo "${Info}用户名：${user}"
	echo "${Info}密码：${pass}"
	echo "${Info}RPC地址：http://token:${token}@$1:6800/jsonrpc"
	echo "${Tip}需要帮助请访问：https://www.xyzbeta.com/"
	echo "---------------------------------------------------------------"
	#清理安装产生的垃圾文件
	#rm -rf /data/aria2/*.zip
	#rm -rf /data/aria2/*.tar.gz
	#rm -rf /data/aria2/*.txt
	#rm -rf /data/aria2/*.md
	#rm -rf /data/aria2/yaaw-*
}

########################业务流程执行入口#########################
check_root
check_sys
echo -e "\n———————————————一键安装Aria2 + Yaaw——————————————
——By xyzbeta Version 1.0 data 2018.5.25
——Blog: https://www.xyzbeta.com
---------------------------------------------------\n
${Tip}本脚本只支持ubantu16/debian8/centos7及以上版本安装，不对低版本进行兼容，使用时请注意。"
read -p "${Info}请对照你的系统版本，如果继续请输入(y/Y):" tag
if [[ "${tag}" != "y" || "${tag}" != "Y" ]]; then
	exit 1
fi
echo -e "${Info}开始一键安装Aria2 + Yaaw...."
updateSource
installaria2
osip=$(curl -4s https://api.ip.sb/ip)
setting ${osip}