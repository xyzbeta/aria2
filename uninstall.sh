#!/bin/bash
#=================================================
#	System Required: CentOS 7+/Debian 8+/Ubuntu 16+
#	Description: 一键卸载Aria2
#	Version: 1.0
#	Author: XyzBeta
#	Blog: https://www.xyzbeta.com
#	Update: 2018/5/25
#=================================================

function uninstall(){
	#关闭服务
	/data/aria2/aria2.sh stop
	#删除caddy
	rm -rf /usr/bin/caddy
	#删除端口
	firewall-cmd --zone=public --remove-port=6080/tcp --permanent
	firewall-cmd --zone=public --remove-port=6800/tcp --permanent
	firewall-cmd --zone=public --remove-port=51413/tcp --permanent
	firewall-cmd --reload
}

echo '------------------------------------'
echo "确认download数据已经备份好了？(Y/N)"
read -p ":" confirm


case $confirm in
	'y')
		uninstall
		rm -rf /data/aria2
		echo '------------------------------------'
		echo "卸载完成！"
		echo '------------------------------------'
		exit
	;;
	'Y')
		uninstall
		rm -rf /data/aria2
		echo '------------------------------------'
		echo "卸载完成！"
		echo '------------------------------------'
		exit
	;;
	'n')
		exit
	;;
	'N')
		exit
	;;
	*)
		echo '参数错误！'
		exit
	;;
esac
