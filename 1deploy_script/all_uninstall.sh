#cat all_uninstall.sh
#!/bin/sh
################################################
# 这个脚本功能是自动卸载基础平台各组件。
# 脚本需要在master节点运行。
# version:1.0 lichengyong
# Date	2017-08-10
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

#uninstall the jdk1.7
uninstallJdk7(){
echo "============所有节点卸载jdk1.7============"
jdk_dir=`cat ${file_name} | grep jdk_dir`
jdk_dir=${jdk_dir#*=}
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
for jdk7_nodes in ${all_nodes[*]}
do
	ssh $jdk7_nodes [ -d "$jdk_dir/jdk1.7.0_79" ]
		if [ $? -eq 0 ];then 
			ssh $jdk7_nodes rm -rf  $jdk_dir/jdk1.7.0_79
		fi
done
check
for jdk7_nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$jdk7_nodes节点jdk目录--- \e[0m"
	ssh $jdk7_nodes [ -d "$jdk_dir/jdk1.7.0_79" ]
		if [ $? -ne 0 ];then 
			echo "jdk目录已删除"
		fi
done
check
action "==========卸载jdk1.7完成==========" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#uninstall the mysql
uninstallMysql(){
echo "============主节点卸载mysql============"
mysql_dir=`cat ${file_name} | grep mysql_dir`
mysql_dir=${mysql_dir#*=} 
mysql_user=`cat ${file_name} | grep mysql_user`
mysql_user=${mysql_user#*=} 
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=} 
this_host=`hostname -s`
for mysql_nodes in ${master_nodes[*]}
do
	if test "$master_nodes" == "$this_host";then  
	echo -e "\e[1;31m ---停止mysql服务--- \e[0m"
		/etc/init.d/mysql stop
		sleep 2
		rm -rf $mysql_dir/mysql
		rm -rf /usr/bin/mysql
	else
		echo "请在Master节点运行安装!"
	fi
done
check
echo -e "\e[1;31m ---查看mysql目录--- \e[0m"
[ -d $mysql_dir/mysql ]
if [ $? -ne 0 ];then 
	echo "mysql目录已删除"
fi
check
action "主节点卸载mysql完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#uninstall the cloudera manager
uninstallCM(){
echo "============所有节点卸载Cloudera Manager=============="
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=} 
slave_nodes=`cat ${file_name} | grep slave_nodes` 
slave_nodes=${slave_nodes#*=} 
this_host=`hostname -s`
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
if test "$master_nodes" == "$this_host";then
echo -e "\e[1;31m ---停止$cmaster_nodes节点cloudera-scm-server服务--- \e[0m"
/opt/cm-5.10.2/etc/init.d/cloudera-scm-server stop
check
sleep 2
mysql -uroot -p123456 -e "
drop database cm;
quit"
	for cmagent_nodes in ${all_nodes[*]}
	do
	echo -e "\e[1;31m ---停止$cmagent_nodes节点cloudera-scm-agent服务--- \e[0m"
	ssh $cmagent_nodes -n "/opt/cm-5.10.2/etc/init.d/cloudera-scm-agent stop"
	sleep 2
	ssh $cmagent_nodes -n "ps -ef | grep cloudera-scm | grep -v grep |  awk '{print $2}' | xargs kill > /dev/null 2>&1"
	ssh $cmagent_nodes -n "umount cm_processes"
	done
else
	echo "请在Master节点运行卸载!"
fi
for nodes in ${all_nodes[*]}
do
	ssh $nodes -n "rm -rf /opt/cm-5.10.2"
	ssh $nodes -n "rm -rf /opt/cloudera"
done
check
for nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$nodes节点cloudera Manager目录--- \e[0m"
	ssh $nodes [ -d "/opt/cm-5.10.2" ]
		if [ $? -ne 0 ];then 
			echo "cloudera Manager目录已删除"
		fi
done
check
action "cloudera Manager卸载完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#uninstall the Orientdb cluster
uninstallOrientdb(){
echo "============指定节点卸载orientdb=============="
orientdb_dir=`cat ${file_name} | grep orientdb_dir`
orientdb_dir=${orientdb_dir#*=} 
orientdb_nodes=`cat ${file_name} | grep orientdb_nodes` 
orientdb_nodes=${orientdb_nodes#*=} 
for db_nodes in ${orientdb_nodes[*]}
do
	echo -e "\e[1;31m ---停止$db_nodes节点orientdb服务--- \e[0m"
	ssh $db_nodes -n "/etc/init.d/orientdb stop"
	sleep 10
	ssh $db_nodes -n "rm -rf $orientdb_dir/orientdb-community-importers-2.2.26"
done
check
for db_nodes in ${orientdb_nodes[*]}
do
	echo -e "\e[1;31m ---查看$nodes节点orientdb目录--- \e[0m"
	ssh $db_nodes [ -d "$orientdb_dir/orientdb-community-importers-2.2.26" ]
		if [ $? -ne 0 ];then 
			echo "orientdb目录已删除"
		fi
done
check
action "卸载orientdb完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#uninstall the elasticsearch5.0
uninstallEs5(){
echo "============指定节点卸载elasticsearch5.0=============="
es5_install_dir=`cat ${file_name} | grep es5_install_dir`  
es5_install_dir=${es5_install_dir#*=} 
es5_nodes=`cat ${file_name} | grep es5_nodes`  
es5_nodes=${es5_nodes#*=}
jdk_dir=`cat ${file_name} | grep jdk_dir`
jdk_dir=${jdk_dir#*=}
for nodes in ${es5_nodes[*]}
do
	echo -e "\e[1;31m ---停止$nodes节点elasticsearch5.0服务--- \e[0m"
	ssh $nodes -n "cat $es5_install_dir/es.pid | xargs kill -SIGTERM > /dev/null 2>&1" 
	ssh $nodes -n "ps -ef | grep govnetes | grep -v grep |  awk '{print $2}' | xargs kill > /dev/null 2>&1" 
	sleep 2
	ssh $nodes -n "rm -rf $es5_install_dir/elasticsearch-5.0.0"
	ssh $nodes -n "rm -rf $es5_install_dir/x-pack-5.0.0.zip"
	ssh $nodes -n "rm -rf $es5_install_dir/x-pack-5.0.0.zip"
	ssh $nodes -n "rm -rf  $jdk_dir/jdk1.8.0_60"
done
check
for nodes in ${es5_nodes[*]}
do
	echo -e "\e[1;31m ---查看$nodes节点elasticsearch5.0目录--- \e[0m"
	ssh $nodes [ -d "$es5_install_dir/elasticsearch-5.0.0" ]
		if [ $? -ne 0 ];then 
			echo "elasticsearch-5.0目录已删除"
		fi
done
check
action "卸载elasticsearch5.0完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#uninstall the elasticsearch1.4.2
uninstallEs1(){
echo "============指定节点卸载elasticsearch1.4.2=============="
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
	sleep 8
	ssh $nodes -n "rm -rf $es1_install_dir/elasticsearch"
done
check
for nodes in ${es1_nodes[*]}
do
	echo -e "\e[1;31m ---查看$nodes节点elasticsearch1.4.2目录--- \e[0m"
	ssh $nodes [ -d "$es1_install_dir/elasticsearch" ]
		if [ $? -ne 0 ];then 
			echo "elasticsearch-1.4.2目录已删除"
		fi
done
check
action "卸载elasticsearch1.4.2完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#uninstall the tomcat
uninstallTomcat(){
echo "============指定节点卸载tomcat=============="
tomcat_dir=`cat ${file_name} | grep tomcat_dir`
tomcat_dir=${tomcat_dir#*=} 
tomcat_node=`cat ${file_name} | grep tomcat_node` 
tomcat_node=${tomcat_node#*=} 
echo -e "\e[1;31m ---$tomcat_node停止tomcat服务--- \e[0m"
ssh $tomcat_node -n "ps -ef | grep tomcat | grep -v grep |  awk '{print $2}' | xargs kill > /dev/null 2>&1" 
sleep 2
ssh $tomcat_node "rm -rf $tomcat_dir/apache-tomcat-8.5.16"
check
ssh $tomcat_node [ -d "$tomcat_dir/apache-tomcat-8.5.16" ]
if [ $? -ne 0 ];then 
echo "apache-tomcat-8.5.16目录已删除"
fi
action "tomcat卸载完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}
