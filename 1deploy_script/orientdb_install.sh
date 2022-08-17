#cat orientdb_install.sh
#!/bin/sh
################################################
# 这个脚本是在指定节点安装orientdb集群。
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

#Install the Orientdb cluster
installOrientdb(){
echo "============指定节点安装orientdb=============="
echo "============脚本用到的安装包orientdb-community-importers-2.2.26.tar.gz需放在/opt目录下============"
orientdb_dir=`cat ${file_name} | grep orientdb_dir`
orientdb_dir=${orientdb_dir#*=} 
orientdb_nodes=`cat ${file_name} | grep orientdb_nodes` 
orientdb_nodes=${orientdb_nodes#*=} 
rmtmp="rm -rf /opt/orientdb-community-importers-2.2.26"
echo -e "\e[1;31m ---新建orientdb安装目录--- \e[0m"
if [ ! -d "$orientdb_dir" ]; then
	for db_nodes in ${orientdb_nodes[*]}
	do
	ssh $db_nodes "mkdir $orientdb_dir > /dev/null 2>&1"
	done
fi
check
echo -e "\e[1;31m ---解压安装orientdb--- \e[0m"
for db_nodes in ${orientdb_nodes[*]}
do
	tar xzf /opt/orientdb-community-importers-2.2.26.tar.gz -C /opt
	scp -rp /opt/orientdb-community-importers-2.2.26 root@$db_nodes:$orientdb_dir > /dev/null
	ssh $db_nodes -n "cp $orientdb_dir/orientdb-community-importers-2.2.26/bin/orientdb.sh /etc/init.d/orientdb"
	ssh $db_nodes -n "/etc/init.d/orientdb start"
	sleep 10
	ssh $db_nodes -n "chkconfig --add orientdb"
done
check
for db_nodes in ${orientdb_nodes[*]}
do
	echo -e "\e[1;31m ---查看orientdb进程状态--- \e[0m"
	ssh $db_nodes -n "/etc/init.d/orientdb status"
done
check
$rmtmp
action "安装orientdb完成" /bin/true
echo "================================================="
echo ""
echo -e '\e[1;31m orientdb安装完成后，即可在浏览器输入  http://节点IP:2480  进入orientdb管理界面 \e[0m'
  sleep 3
}
