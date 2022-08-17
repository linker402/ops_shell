#cat deploy_main.sh
#!/bin/sh
################################################
# 这个脚本是自动化部署主菜单，
# version:1.0 lichengyong
################################################

#date
DATE=`date +"%y-%m-%d %H:%M:%S"`
#ip
IPADDR=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
#hostname
HOSTNAME=`hostname -s`
#user
USER=`whoami`
#disk_check
DISK_SDA=`df -h |grep -w "/" |awk '{print $4}'`
#cpu_average_check
cpu_uptime=`cat /proc/loadavg|awk '{print $1,$2,$3}'`
  
#set LANG
export LANG=zh_CN.UTF-8
 
#Require root to run this script.
uid=`id | cut -d\( -f1 | cut -d= -f2`
if [ $uid -ne 0 ];then
  action "Please run this script as root." /bin/false
  exit 1
fi
#"stty erase ^H"
\cp /root/.bash_profile  /root/.bash_profile_$(date +%F)
erase=`grep -wx "stty erase ^H" /root/.bash_profile |wc -l`
if [ $erase -lt 1 ];then
    echo "stty erase ^H" >>/root/.bash_profile
    source /root/.bash_profile
fi

#menu5
menu5(){
while true
do
clear
cat << EOF
-----------------------------------------------
|*************请选择下列选项:[0-7]*************|
-----------------------------------------------
(1) 卸载jdk1.7
(2) 卸载mysql
(3) 卸载Cloudera Manager
(4) 卸载Orientdb
(5) 卸载elasticsearch5.0
(6) 卸载elasticsearch1.4.2
(7) 卸载Tomcat
(0) 返回上一级菜单
EOF
read -p "请输入操作选项并回车[0-7]: " input5
case "$input5" in
  0)
  clear
  break 
  ;;
  1) 
  source ./all_uninstall.sh
  uninstallJdk7
  ;;
  2)
  source ./all_uninstall.sh
  uninstallMysql
  ;;
  3)
  source ./all_uninstall.sh
  uninstallCM
  ;;
  4)
  source ./all_uninstall.sh
  uninstallOrientdb
  ;;
  5)
  source ./all_uninstall.sh
  uninstallEs5
  ;;
  6)
  source ./all_uninstall.sh
  uninstallEs1
  ;;
  7)
  source ./all_uninstall.sh
  uninstallTomcat
  ;;
  *) 
  echo "----------------------------------"
  echo "|            警告!!!             |"
  echo "|      请输入正确的选项!!!       |"
  echo "----------------------------------"
  for i in `seq -w 3 -1 1`
    do 
        echo -ne "\b\b$i";
		sleep 1;
	done
  clear
esac
done
}

#menu4
menu4(){
while true
do
clear
cat << EOF
-----------------------------------------------
|*************请选择下列选项:[0-6]*************|
-----------------------------------------------
(1) 停止mysql
(2) 停止Cloudera Manager
(3) 停止Orientdb
(4) 停止elasticsearch5.0
(5) 停止elasticsearch1.4.2
(6) 停止Tomcat
(0) 返回上一级菜单
EOF
read -p "请输入操作选项并回车[0-6]: " input4
case "$input4" in
  0)
  clear
  break 
  ;;
  1) 
  source ./all_stop.sh
  stopMysql
  ;;
  2)
  source ./all_stop.sh
  stopCM
  ;;
  3)
  source ./all_stop.sh
  stopOrientdb
  ;;
  4)
  source ./all_stop.sh
  stopEs5
  ;;
  5)
  source ./all_stop.sh
  stopEs1
  ;;
  6)
  source ./all_stop.sh
  stopTomcat 
  ;;
  *) 
  echo "----------------------------------"
  echo "|            警告!!!             |"
  echo "|      请输入正确的选项!!!       |"
  echo "----------------------------------"
  for i in `seq -w 3 -1 1`
    do 
        echo -ne "\b\b$i";
		sleep 1;
	done
  clear
esac
done
}

#menu3
menu3(){
while true
do
clear
cat << EOF
-----------------------------------------------
|*************请选择下列选项:[0-6]*************|
-----------------------------------------------
(1) 启动mysql
(2) 启动Cloudera Manager
(3) 启动Orientdb
(4) 启动elasticsearch5.0
(5) 启动elasticsearch1.4.2
(6) 启动Tomcat
(0) 返回上一级菜单
EOF
read -p "请输入操作选项并回车[0-6]: " input3
case "$input3" in
  0)
  clear
  break 
  ;;
  1) 
  source ./all_start.sh
  startMysql
  ;;
  2)
  source ./all_start.sh
  startCM
  ;;
  3)
  source ./all_start.sh
  startOrientdb
  ;;
  4)
  source ./all_start.sh
  startEs5
  ;;
  5)
  source ./all_start.sh
  startEs1
  ;;
  6)
  source ./all_start.sh
  startTomcat  
  ;;
  *) 
  echo "----------------------------------"
  echo "|            警告!!!             |"
  echo "|      请输入正确的选项!!!       |"
  echo "----------------------------------"
  for i in `seq -w 3 -1 1`
    do 
        echo -ne "\b\b$i";
		sleep 1;
	done
  clear
esac
done
}

#menu2
menu2(){
while true
do
clear
cat << EOF
-----------------------------------------------
|*************请选择下列选项:[0-8]*************|
-----------------------------------------------
(1) 一键安装(自动运行2-8)
(2) 安装jdk1.7
(3) 安装mysql
(4) 安装Cloudera Manager
(5) 安装Orientdb
(6) 安装elasticsearch5.0
(7) 安装elasticsearch1.4.2
(8) 安装Tomcat
(0) 返回上一级菜单
EOF
read -p "请输入操作选项并回车，首次安装请按顺序选择[0-8]: " input2
case "$input2" in
  0)
  clear
  break 
  ;;
  1) 
  source ./jdk7_install.sh
  installJdk7
  source ./mysql_install.sh
  installMysql
  source ./cm_install.sh
  installCM  
  source ./orientdb_install.sh
  installOrientdb
  source ./es5_install.sh  
  installEs5
  source ./es1_install.sh
  installEs1
  source ./tomcat_install.sh
  installTomcat
  ;;
  2)
  source ./jdk7_install.sh
  installJdk7
  ;;
  3)
  source ./mysql_install.sh
  installMysql
  ;;
  4)
  source ./cm_install.sh
  installCM
  ;;
  5)
  source ./orientdb_install.sh
  installOrientdb
  ;;
  6)
  source ./es5_install.sh  
  installEs5
  ;;
  7)
  source ./es1_install.sh
  installEs1
  ;;
  8)
  source ./tomcat_install.sh
  installTomcat
  ;;
  *) 
  echo "----------------------------------"
  echo "|            警告!!!             |"
  echo "|      请输入正确的选项!!!       |"
  echo "----------------------------------"
  for i in `seq -w 3 -1 1`
    do 
        echo -ne "\b\b$i";
		sleep 1;
	done
  clear
esac
done
}

#menu1
menu1(){
while true
do
clear
cat << EOF
-----------------------------------------------
|*************请选择下列选项:[0-10]*************|
-----------------------------------------------
(1) 一键优化(自动运行2-10)
(2) 配置本地YUM软件源
(3) 配置SSH免密码登录
(4) 禁用SELINUX及关闭防火墙
(5) 配置所有节点YUM源
(6) 配置中文字符集
(7) 配置时间同步
(8) 系统参数优化
(9) 内核参数优化
(10) 禁止透明大页 
(11) 新建用户
(0) 返回上一级菜单
EOF
read -p "请输入操作选项并回车[0-10]: " input1
case "$input1" in
  0)
  clear
  break 
  ;;
  1) 
  source ./os_conf.sh
  localyum
  autoSsh
  initFirewall
  configYum
  initI18n
  syncSysTime
  initLimits
  initSysctl
  initPage
  ;;
  2)
  source ./os_conf.sh
  localyum
  ;;
  3)
  source ./os_conf.sh
  autoSsh
  ;;
  4)
  source ./os_conf.sh
  initFirewall
  ;;
  5)
  source ./os_conf.sh
  configYum
  ;;
  6)
  source ./os_conf.sh
  initI18n  
  ;;
  7)
  source ./os_conf.sh
  syncSysTime
  ;;
  8)
  source ./os_conf.sh
  initLimits
  ;;
  9)
  source ./os_conf.sh
  initSysctl
  ;;
  10)
  source ./os_conf.sh 
  initPage
  ;;
  11)
  source ./os_conf.sh
  addUser
  ;;
  *) 
  echo "----------------------------------"
  echo "|            警告!!!             |"
  echo "|      请输入正确的选项!!!       |"
  echo "----------------------------------"
  for i in `seq -w 3 -1 1`
    do 
        echo -ne "\b\b$i";
		sleep 1;
	done
  clear
esac
done
}

#menu
while true
do
clear
echo "============================================="
echo '        The deployment of installation       '   
echo "============================================="
cat << EOF
|---------------操作系统运行信息---------------
| 日期            :$DATE
| 主机名          :$HOSTNAME
| 当前用户        :$USER
| 主机IP          :$IPADDR
| 根目录使用情况  :$DISK_SDA
| CPU平均负载     :$cpu_uptime
-----------------------------------------------
|*************请选择下列选项:[0-5]*************|
-----------------------------------------------
(1) 操作系统配置优化
(2) 基础平台一键安装
(3) 基础平台一键启动
(4) 基础平台一键停止
(5) 基础平台一键卸载
(0) 退出
EOF

#choice
read -p "请输入操作选项并回车[0-5]: " input
 
case "$input" in
0) 
  clear 
  exit
  ;;
1) 
  menu1
  ;;
2) 
  menu2
  ;;
3) 
  menu3
  ;; 
4) 
  menu4
  ;;  
5) 
  menu5
  ;;
*)   
  echo "----------------------------------"
  echo "|            警告!!!             |"
  echo "|      请输入正确的选项!!!       |"
  echo "----------------------------------"
  for i in `seq -w 3 -1 1`
	do
		echo -ne "\b\b$i";
		sleep 1;
	done
  clear
esac  
done
