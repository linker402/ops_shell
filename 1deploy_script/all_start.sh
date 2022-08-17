#cat all_start.sh
#!/bin/sh
#!/usr/bin/expect  -f
################################################
# 这个脚本是启动基础平台相关服务。
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

#start mysql
startMysql(){
echo "============启动mysql=============="
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=} 
this_host=`hostname -s`
for mysql_nodes in ${master_nodes[*]}
do
	if test "$mysql_nodes" == "$this_host";then
		/etc/init.d/mysql start
		sleep 3
	else
		echo "请在Master节点运行启动!"
	fi
done
check
echo -e "\e[1;31m ---查看$master_nodes mysql进程状态--- \e[0m"
/etc/init.d/mysql status
check
action "启动mysql完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#start CM
startCM(){
echo "============启动cmserver和cmagent=============="
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=}  
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
this_host=`hostname -s`
if test "$master_nodes" == "$this_host";then
/etc/init.d/cloudera-scm-server start
sleep 3
else
  echo "请在Master节点运行启动!"
fi
for cmagent_nodes in ${all_nodes[*]}
do
	ssh $cmagent_nodes -n "/etc/init.d/cloudera-scm-agent start"
	sleep 3
done
check
echo -e "\e[1;31m ---查看$master_nodes cloudera-scm-server进程状态--- \e[0m"
/etc/init.d/cloudera-scm-server status
action "主节点cm-server启动完成" /bin/true
echo "================================================="
for cmagent_nodes in ${all_nodes[*]}
do
echo "查看$cmagent_nodes节点cloudera-scm-agent进程状态"
ssh $cmagent_nodes -n "/etc/init.d/cloudera-scm-agent status"
done
check
action "slave节点cm-agent启动完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#start orientdb
startOrientdb(){
echo "============指定节点启动orientdb=============="
orientdb_nodes=`cat ${file_name} | grep orientdb_nodes` 
orientdb_nodes=${orientdb_nodes#*=} 
for db_nodes in ${orientdb_nodes[*]}
do
	ssh $db_nodes -n "/etc/init.d/orientdb start"
	sleep 3
done
check
for db_nodes in ${orientdb_nodes[*]}
do
	echo -e "\e[1;31m ---查看$db_nodes orientdb进程状态--- \e[0m"
	ssh $db_nodes -n "/etc/init.d/orientdb status"
	sleep 2
done
check
action "启动orientdb完成" /bin/true
echo "================================================="
echo ""
echo -e '\e[1;31m orientdb安装完成后，即可在浏览器输入  http://节点ip:2480  进入orientdb管理界面 \e[0m'
  sleep 3
}

#start elasticsearch5.0
startEs5(){
echo "============启动elasticsearch5.0集群=============="
#安装目录  
es5_install_dir=`cat ${file_name} | grep es5_install_dir`  
es5_install_dir=${es5_install_dir#*=}  
#es节点
es5_nodes=`cat ${file_name} | grep es5_nodes`  
es5_nodes=${es5_nodes#*=}
for es_nodes in ${es5_nodes[*]}
do
	ssh $es_nodes -n "su - govnetes << EOF
source $userhome/.bash_profile
$es5_install_dir/elasticsearch-5.0.0/bin/elasticsearch -d -p es.pid
exit
EOF
"
#	ssh $es_nodes -n "su - govnetes << EOF
#nohup $es5_install_dir/kibana-5.0.0-linux-x86_64/bin/kibana > /dev/null 2>&1 &
#exit
#EOF
#"
done
check
sleep 8
for es_nodes in ${es5_nodes[*]}
do
	echo -e "\e[1;31m ---查看$es_nodes es服务9200页面--- \e[0m"
	sleep 5
	curl  -XGET "$es_nodes:9200"
done
check
action "启动es5.0集群完成" /bin/true
echo "================================================="
echo ""
echo -e '\e[1;31m es5.0安装完成后，即可在浏览器输入  http://master ip:9200/_cluster/health?pretty  查看es集群状态"status" : "green"则正常 \e[0m'
  sleep 3
}

#start the elasticsearch1.4
startEs1(){
echo "============启动elasticsearch1.4集群=============="
#安装目录  
es1_install_dir=`cat ${file_name} | grep es1_install_dir`  
es1_install_dir=${es1_install_dir#*=} 
#es节点  
es1_nodes=`cat ${file_name} | grep es1_nodes`  
es1_nodes=${es1_nodes#*=}  
for nodes in ${es1_nodes[*]}
do
	echo -e "\e[1;31m ---$nodes启动es1.4.2-- \e[0m"
	./expect_start_es1.sh $nodes $es1_install_dir > /dev/null
	sleep 5
done 
check
for nodes in ${es1_nodes[*]}
do
	echo -e "\e[1;31m ---$nodes查看es进程状态-- \e[0m"
	ssh $nodes -n "$es1_install_dir/elasticsearch/elasticsearch/bin/service/elasticsearch status"
	sleep 5
	echo -e "\e[1;31m ---$nodes查看es服务9200页面-- \e[0m"
	curl  -XGET "$nodes:9200"
done
check
action "启动es1.4完成" /bin/true
echo "================================================="
echo ""
echo -e '\e[1;31m es1.4.2安装完成后，即可在浏览器输入  http://master ip:19200/_cluster/health?pretty  查看es集群状态"status" : "green"则正常 \e[0m'
  sleep 3
}

#start the tomcat
startTomcat(){
echo "============指定节点启动tomcat=============="
tomcat_dir=`cat ${file_name} | grep tomcat_dir`
tomcat_dir=${tomcat_dir#*=} 
tomcat_node=`cat ${file_name} | grep tomcat_node` 
tomcat_node=${tomcat_node#*=}
echo -e "\e[1;31m ---$tomcat_node启动tomcat服务--- \e[0m"
ssh $tomcat_node "$tomcat_dir/apache-tomcat-8.5.16/bin/startup.sh"
check
sleep 10
echo -e "\e[1;31m ---查看$tomcat_node tomcat是否启动成功，8080端口有监听---\e[0m"
ssh $tomcat_node "netstat -an | grep 8080"
action "tomcat启动完成" /bin/true
echo "================================================="
echo ""
echo -e "\e[1;31m tomcat安装完成后，即可在浏览器输入  http://$tomcat_node:8080 打开tomcat主页 \e[0m"
  sleep 3
}
