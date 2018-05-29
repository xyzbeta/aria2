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

##########################业务方法区########################
startservice(){
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
}
stopservice(){
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
}
restartservice(){
	stopservice
	startservice
}
statusservice(){
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
}

########################业务流程执行入口#########################
check_root
while true
do
aria2pid=$(pgrep 'aria2c')
caddypid=$(pgrep 'caddy')
echo -e "\n——————————————————Aria2运维工具—————————————————
——By xyzbeta Version 1.0 data 2018.5.25
——Blog: https://www.xyzbeta.com
---------------------------------------------------\n
${Green_font_prefix}1.${Font_color_suffix}启动服务
${Green_font_prefix}2.${Font_color_suffix}停止服务
${Green_font_prefix}3.${Font_color_suffix}重启服务
${Green_font_prefix}4.${Font_color_suffix}查看状态
${Green_font_prefix}0.${Font_color_suffix}退出"
echo -n "按照上述功能说明,输入相应的编号(0-4):" && read num
case ${num} in
0) exit ;;
1) startservice ;;
2) stopservice ;;
3) restartservice ;;
4) statusservice ;;
*) echo -e "${Tip}你输入的是:${num},这个功能选项并不在功能列表中" ;;
esac
done;
