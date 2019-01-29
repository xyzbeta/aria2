#!/bin/bash
#=================================================
#	System Required: CentOS 7+/Debian 8+/Ubuntu 16+
#	Description: 一键安装Aria2 + AriaNg + Caddy
#	Version: 2.0
#	Author: XyzBeta
#	Blog: https://www.xyzbeta.com
#	Update: 2019/1/28
#=================================================

##############变量配置区域#############
#字体颜色
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Yellow_font_prefix="\033[33m" && Font_color_suffix="\033[0m"
#提示信息
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

basedir=$(cd $(dirname $0); pwd -P)
sys_date=$(date "+%Y%m%d_%H%M%S")
osip=$(curl -4s https://api.ip.sb/ip)
sh_version="2.0"


##############基础方法区域###########
#判断用户是否具有root 权限
function check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && exit 1
}

#判断系统发行版本
function check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|redhat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|redhat|redhat"; then
		release="centos"
    fi
	[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
}

#脚本升级
function Update_Sh(){
	echo -e "${Info}当前文件版本为:${sh_version},开始检查是否存在新版本！"
	sh_new_version=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/xyzbeta/aria2/master/laac.sh"|grep 'sh_version="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_version} ]] && echo -e "文件升级检查失败,脚本将退出。" && exit 0
	if [[ ! ${sh_version} == ${sh_new_version} ]]; then
		echo -e "${info}发现新版${sh_new_version},是否进行升级。[Y/n]"
		 read yn
		[[ -z ${yn} ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			 wget --no-check-certificate -N https://raw.githubusercontent.com/xyzbeta/aria2/master/laac.sh && chmod u+x *.sh
		else 
		 echo -e "${Tip}取消更新!"
		fi
		echo && echo -e "${Info}脚本已经更新到最新版本:${sh_new_version},请重新运行本脚本" && echo
	else
		echo -e "${Info}当前版本为最新版本。"
	fi
	
	
}

################业务方法区####################
#更新系统镜像源
function updateSource(){
	echo -e "${Info}修改${release}系统的镜像源为阿里云下载源"
	if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		echo -e "${Info}保存系统默认镜像源文件"
		debian_source=$(find /etc/apt/ -name "sources.list")
		cp ${debian_source} ${debian_source}_${sys_date}
		cat /dev/null>${debian_source}
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
	elif [[ "${release}" == "centos" || "${release}" == "redhat" ]]; then
		echo -e "${Info}保存系统默认镜像源文件"
		centos_soure=$(find /etc/yum.repos.d/ -name "CentOS-Base.repo")
		cp ${centos_soure} ${centos_soure}_${sys_date}
		rm -f ${centos_source}
		wget --no-check-certificate https://mirrors.163.com/.help/CentOS7-Base-163.repo -O /etc/yum.repos.d/CentOS-Base.repo
		rm -rf /var/cache/yum/
		yum makecache
		yum -y update
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
	echo -e "${Info}设置用户名:\c" && read user
	echo -e "${Info}设置密码:\c"  && read pass
	echo -e "${Info}设置连接口令:\c"  && read token
	sed -i "s/rpc-secret=/rpc-secret=${token}/g" /data/aria2/aria2.conf
	#移动yaaw
	mv index.html /data/aria2
	#移动caddy
	mv caddy/caddy.filemanager /usr/bin/caddy
	chmod +x /usr/bin/caddy
	#修改配置
	sed -i "s/username/${user}/g" /data/aria2/caddy.conf
	sed -i "s/password/${pass}/g" /data/aria2/caddy.conf
	#放行端口
	if [[ "${release}" == "centos" ]]; then
		echo -e "${Info}放行6080、6800、51413端口"
		chk_firewall
	fi
	#启动服务
	cd /data/aria2
	nohup aria2c --conf-path=/data/aria2/aria2.conf > /data/aria2/aria2.log 2>&1 &
	nohup caddy -conf="/data/aria2/caddy.conf" > /data/aria2/caddy.log 2>&1 &
	echo "------------------安装完成，请牢记以下信息。------------------"
	echo -e "${Info}访问地址：http://${osip}:6080"
	echo -e "${Info}用户名：${user}"
	echo -e "${Info}密码：${pass}"
	echo -e "${Info}RPC地址：http://token:${token}@$1:6800/jsonrpc"
	echo -e "${Tip}需要帮助请访问：https://www.xyzbeta.com/"
	echo "---------------------------------------------------------------"
	#清理安装产生的垃圾文件
	rm -rf /data/aria2/*.zip
	rm -rf /data/aria2/*.tar.gz
	rm -rf /data/aria2/*.txt
	rm -rf /data/aria2/*.md
}

#服务卸载
function laac_uninstall(){
	#关闭服务
	laac_service stop
	#删除caddy
	rm -rf /usr/bin/caddy
	#删除端口
	if [[ ${release} == "centos" ]]; then
	firewall-cmd --zone=public --remove-port=6080/tcp --permanent
	firewall-cmd --zone=public --remove-port=6800/tcp --permanent
	firewall-cmd --zone=public --remove-port=51413/tcp --permanent
	firewall-cmd --reload
	fi
	rm -rf /data/aria2
	echo -e "${Info}服务卸载成功"
}

#服务管理
function laac_service(){
	aria2pid=$(pgrep 'aria2c')
	caddypid=$(pgrep 'caddy')
	if [[ "start" == $1 ]]; then
		if [[ "${aria2pid}" == "" && "${caddypid}" == "" ]]; then
			nohup aria2c --conf-path=/data/aria2/aria2.conf > /data/aria2/aria2.log 2>&1 &
			if [[ "0" != "$?" ]]; then
				echo -e "${Error}aria2服务启动失败，请查看aria2.log日志记录！"
			else
				echo -e "${Info}aria2启动成功！"
			fi
			nohup caddy -conf="/data/aria2/caddy.conf" > /data/aria2/caddy.log 2>&1 &
			if [[ "0" != "$?" ]]; then
			echo -e "${Error}caddy服务启动失败，请查看caddy.log日志记录！"
		else
			echo -e "${Info}caddy启动成功！"
		fi		
		else
			echo -e "${Tip}服务正在运行,你需要先停止该服务,在进行重启！"
		fi
	elif [[  "stop" == $1 ]]; then
		if [[ "${aria2pid}" == "" ]]; then
			echo -e "${Tip}aria2服务未运行。"
		else
			kill -9 ${aria2pid}
		echo -e "${Info}aria2服务停止!"
		fi
		if [[ "${caddypid}" == "" ]]; then
			echo -e "${Tip}caddy2服务未运行。"
		else
			kill -9 ${caddypid}
			echo -e "${Info}caddy服务停止!"
		fi
	elif [[ "status" == $1 ]]; then
		if [ "${aria2pid}" == "" ]; then
			echo -e "${Error}aria2服务未运行！"
		else
			echo -e "${Info}aria2服务正在运行,进程ID:${aria2pid}"
		fi
		if [ "${caddypid}" == "" ]; then
			echo -e "${Error}caddy服务未运行！"
		else
			echo -e "${Info}caddy服务正在运行,进程ID:${caddypid}"
		fi
	fi
}


#####################################################################################################
#################业务流程整合区###################
#服务安装
function laac_install(){
	updateSource
	chk_firewall
	installaria2
	setting ${osip}
}

###################脚本功能执行入口###############
check_sys
check_root
until [[ "0" == ${num} ]]
do
echo && echo -e "Arira2\AriaNg\Caddy自动化运维管理脚本 ${Green_font_prefix}[${sh_version}]${Font_color_suffix}
-- XyzBeta | https://github.com/xyzbeta/aria2 --
 ${Green_font_prefix}1.${Font_color_suffix} 安装
 ${Green_font_prefix}2.${Font_color_suffix} 卸载
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动
 ${Green_font_prefix}4.${Font_color_suffix} 停止
 ${Green_font_prefix}5.${Font_color_suffix} 重启
 ${Green_font_prefix}6.${Font_color_suffix} 查看 运行状态
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 升级脚本
 ${Green_font_prefix}0.${Font_color_suffix} 退出
 "
echo && read -p "请输入数字 [0-8]：" num && echo
case "${num}" in
	0)
	exit 0
	;;
	1)
	laac_install
	;;
	2)
	laac_uninstall
	;;
	3)
	laac_service start
	;;
	4)
	laac_service stop
	;;
	5)
	laac_service stop
	laac_service start
	;;
	6)
	laac_service status
	;;
	7)
	Update_Sh
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [0-7]"
	;;
esac
done
