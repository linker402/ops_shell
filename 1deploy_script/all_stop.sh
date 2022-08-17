#cat all_stop.sh
#!/bin/sh
#!/usr/bin/expect  -f
################################################
# 这个脚本是停止基础平台相关服务。
# version:1.0 lichengyong
# Date 2017-08-10
################################################
 
#Source function library.
 
. /etc/init.d/functions
 
#date
DATE=`date +"%y-%m-%d %H:%M:%S"`
  
#set LANG
export LANG=zh_CN.UTF-8

file_name="./deploy.conf" 

#---定义检查函数---
check() {
if [ $? != 0 ]
then 
	echo -e '\e[1;33m ERROR \e[0m'
	exit 1
else
	echo -e '\e[1;31m OK \e[0m'
fi
}

#stop mysql
stopMysql(){
echo "============启动mysql=============="
mysql_dir=`cat ${file_name} | grep mysql_dir`
mysql_dir=${mysql_dir#*=} 
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=} 
this_host=`hostname -s`
for mysql_nodes in ${master_nodes[*]}
do
	if test "$mysql_nodes" == "$this_host";then
		/etc/init.d/mysql stop
		sleep 3
	else
		echo "请在Master节点运行停止!"
	fi
done
check
echo -e "\e[1;31m ---查看$master_nodes mysql进程状态--- \e[0m"
/etc/init.d/mysql status
action "停止mysql完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#stop CM
stopCM(){
echo "============停止cmserver和cmagent=============="
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=} 
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
this_host=`hostname -s`
if test "$master_nodes" == "$this_host";then
/etc/init.d/cloudera-scm-server stop
sleep 3
else
  echo "请在Master节点运行停止!"
fi
for cmagent_nodes in ${all_nodes[*]}
do
	ssh $cmagent_nodes -n "/etc/init.d/cloudera-scm-agent stop"
	sleep 3
done
check
echo -e "\e[1;31m ---查看$master_nodes cloudera-scm-server进程状态--- \e[0m"
/etc/init.d/cloudera-scm-server status
action "主节点cm-server停止完成" /bin/true
echo "================================================="
for cmagent_nodes in ${all_nodes[*]}
do
echo "查看$cmagent_nodes节点cloudera-scm-agent进程状态"
ssh $cmagent_nodes -n "/etc/init.d/cloudera-scm-agent status"
done
action "slave节点cm-agent停止完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#stop orientdb
stopOrientdb(){
echo "============指定节点停止orientdb=============="
orientdb_nodes=`cat ${file_name} | grep orientdb_nodes` 
orientdb_nodes=${orientdb_nodes#*=} 
for db_nodes in ${orientdb_nodes[*]}
do
	ssh $db_nodes -n "/etc/init.d/orientdb stop"
	sleep 5
done
check
for db_nodes in ${orientdb_nodes[*]}
do
	echo -e "\e[1;31m ---查看$db_nodes orientdb进程状态--- \e[0m"
	sleep 2
	ssh $db_nodes -n "/etc/init.d/orientdb status"
done
action "停止orientdb完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#stop elasticsearch5.0
stopEs5(){
echo "============停止elasticsearch5.0集群=============="
#安装目录  
es5_install_dir=`cat ${file_name} | grep es5_install_dir`  
es5_install_dir=${es5_install_dir#*=}  
#es节点  
es5_nodes=`cat ${file_name} | grep es5_nodes`  
es5_nodes=${es5_nodes#*=}
for es_nodes in ${es5_nodes[*]}
do
	echo -e "\e[1;31m ---停止$nodes节点elasticsearch5.0服务--- \e[0m"
	ssh $es_nodes -n "cat $es5_install_dir/es.pid | xargs kill -SIGTERM > /dev/null 2>&1" 
	ssh $es_nodes -n "ps -ef | grep govnetes | grep -v grep |  awk '{print $2}' | xargs kill > /dev/null 2>&1" 
	sleep 2
done
check
for es_nodes in ${es5_nodes[*]}
do
	echo -e "\e[1;31m ---$es_nodes查看es是否成功停止，无9200端口监听--- \e[0m"
	ssh $es_nodes -n "netstat -apn | grep 9200"
done
action "停止es5.0集群完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#stop the elasticsearch1.4
stopEs1(){
echo "============启动elasticsearch1.4集群=============="
es1_install_dir=`cat ${file_name} | grep es1_install_dir`  
es1_install_dir=${es1_install_dir#*=} 
es1_nodes=`cat ${file_name} | grep es1_nodes`  
es1_nodes=${es1_nodes#*=}
chmodes="chmod +x ${es1_install_dir}/elasticsearch/elasticsearch/bin/service/elasticsearch"
for nodes in ${es1_nodes[*]}
do
	echo -e "\e[1;31m ---停止$nodes节点elasticsearch1.4.2服务--- \e[0m"
	ssh $nodes -n "$chmodes"
	ssh $nodes -n "$es1_install_dir/elasticsearch/elasticsearch/bin/service/elasticsearch stop" 
	sleep 3
done
check
for nodes in ${es1_nodes[*]}
do
	echo -e "\e[1;31m ---$es_nodes查看es是否成功停止，无9200端口监听--- \e[0m"
	ssh $nodes -n "netstat -apn | grep 9200"
done
action "停止es1.4集群完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#stop the tomcat
stopTomcat(){
echo "============指定节点停止tomcat=============="
tomcat_dir=`cat ${file_name} | grep tomcat_dir`
tomcat_dir=${tomcat_dir#*=} 
tomcat_node=`cat ${file_name} | grep tomcat_node` 
tomcat_node=${tomcat_node#*=} 
echo -e "\e[1;31m ---$tomcat_node停止tomcat服务--- \e[0m"
ssh $tomcat_node -n "ps -ef | grep tomcat | grep -v grep |  awk '{print $2}' | xargs kill > /dev/null 2>&1" 
sleep 2
echo -e "\e[1;31m ---查看$tomcat_node tomcat是否停止成功，无8080端口监听--- \e[0m"
ssh $tomcat_node "netstat -an | grep 8080"
action "tomcat停止完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}
