#cat es5_install.sh
#!/bin/sh
################################################
# 这个脚本是在指定节点安装elasticsearch5.0集群。
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

#if [ $# -lt 1 ]
#then
#        echo "Usage: sh es5_linstall.sh 节点1IP 节点2IP"
#        exit -1
#fi

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

#Install the elasticsearch5.0
installEs5(){
echo "============指定节点安装elasticsearch5.0=============="
echo "============脚本用到的安装包elasticsearch-5.0.0.zip，kibana-5.0.0-linux-x86_64.tar.gz，x-pack-5.0.0.zip，jdk-8u60-linux-x64.tar.gz需放在/opt目录下============"
#es用户
es_user=`cat ${file_name} | grep es_user`
es_user=${es_user#*=}
userhome=`cat /etc/passwd | grep $es_user | awk -F: '{print $6}'` 
#安装目录  
es5_install_dir=`cat ${file_name} | grep es5_install_dir`  
es5_install_dir=${es5_install_dir#*=}  
#es数据目录  
es5_data_dirs=`cat ${file_name} | grep es5_data_dirs`  
es5_data_dirs=${es5_data_dirs#*=}
es5_datadir_nu=`echo "$es5_data_dirs"|sed 's/,/ /g'`
#es节点  
es5_nodes=`cat ${file_name} | grep es5_nodes`  
es5_nodes=${es5_nodes#*=}
es5_nodes_dd=`echo "$es5_nodes"|sed 's/ /,/g'`
es5_nodes_1=`echo "$es5_nodes"|awk '{print $1}'`
es5_nodes_oth=`echo $es5_nodes|awk '{split ($0,a," ")};{for (i=2;i<=NF;i++) print a[i]}' | xargs`
jdk_dir=`cat ${file_name} | grep jdk_dir`
jdk_dir=${jdk_dir#*=}
rmtmpes="rm -rf /opt/elasticsearch-5.0.0"
rmtmpkib="rm -rf /opt/kibana-5.0.0-linux-x86_64"
es_log_dir="mkdir -p /var/log/es5/logs"
echo -e "\e[1;31m ---新建jdk8安装目录--- \e[0m"
for jdk_nodes in ${es5_nodes[*]}
do
	ssh $jdk_nodes [ -d "$jdk_dir" ]
	if [ $? -ne 0 ];then 
		ssh $jdk_nodes mkdir $jdk_dir
	fi
done
check
echo -e "\e[1;31m ---解压安装jdk8和elasticsearch5.0--- \e[0m"
tar zxf /opt/jdk-8u60-linux-x64.tar.gz -C $jdk_dir
unzip /opt/elasticsearch-5.0.0.zip -d /opt > /dev/null
#判断用户是否存在
egrep "^$es_user" /etc/passwd >& /dev/null  
if [ $? -ne 0 ]
then
   echo "---建立govnetes用户---"
   source ./os_conf.sh
   addUser  
fi 
check
for es_nodes in ${es5_nodes[*]}
do
	for dirs in ${es5_datadir_nu[*]} 
	do 
		ssh $es_nodes -n "mkdir -p $dirs > /dev/null 2>&1"
		ssh $es_nodes -n "chown -R govnetes:govnetes $dirs"
	done
	scp -rp $jdk_dir/jdk1.8.0_60 root@$es_nodes:$jdk_dir > /dev/null
	ssh $es_nodes -n "chown -R govnetes:govnetes /usr/java/jdk1.8.0_60"
	if ssh $es_nodes -n 'grep -q "JAVA_HOME=/usr/java/jdk1.8.0_60" /home/govnetes/.bash_profile';then
		continue
	else
	ssh $es_nodes -n "echo '
export JAVA_HOME=/usr/java/jdk1.8.0_60
export PATH="\$JAVA_HOME/bin:\$PATH"
export CLASSPATH=.:"\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar"
' >> $userhome/.bash_profile"
	fi
	scp -rp /opt/elasticsearch-5.0.0 root@$es_nodes:$es5_install_dir > /dev/null
	ssh $es_nodes -n "chown -R govnetes:govnetes $es5_install_dir/"
	scp /opt/x-pack-5.0.0.zip root@$es_nodes:$es5_install_dir > /dev/null
	ssh $es_nodes -n "chown -R govnetes:govnetes $es5_install_dir"
	ssh $es_nodes -n "echo '
cluster.name: govnetesv5
node.name: $es_nodes
node.attr.rack: r1
path.data: $es5_data_dirs
path.logs: /var/log/es5/logs
bootstrap.memory_lock: true
network.host: $es_nodes
http.port: 9200
discovery.zen.ping.unicast.hosts: [$es5_nodes_dd]
discovery.zen.minimum_master_nodes: 1
gateway.recover_after_nodes: 1
node.max_local_storage_nodes: 1
action.destructive_requires_name: true
xpack.security.enabled: false
node.master: true
node.data: true
node.ingest: true
' >> $es5_install_dir/elasticsearch-5.0.0/config/elasticsearch.yml"
	ssh $es_nodes -n "$es_log_dir > /dev/null 2>&1"
	ssh $es_nodes -n "chown -R govnetes:govnetes /var/log/es5/logs"
	ssh $es_nodes -n "sed -i 's/-Xms2g/-Xms8g/' $es5_install_dir/elasticsearch-5.0.0/config/jvm.options"
	ssh $es_nodes -n "sed -i 's/-Xmx2g/-Xmx8g/' $es5_install_dir/elasticsearch-5.0.0/config/jvm.options"
	ssh $es_nodes -n "sed -i 's/1024/10240/' /etc/security/limits.d/90-nproc.conf"
done
check
echo -e "\e[1;31m ---解压安装x-pack插件--- \e[0m"
for es_nodes in ${es5_nodes[*]}
do
	ssh $es_nodes -n "su - govnetes << EOF
source /home/govnetes/.bash_profile
/home/govnetes/elasticsearch-5.0.0/bin/elasticsearch-plugin install file:///home/govnetes/x-pack-5.0.0.zip > /dev/null
exit
EOF
"
done
check
for esoth_nodes in ${es5_nodes_oth[*]}
do
ssh $esoth_nodes "sed -i 's/node.master: true/node.master: false/' $es5_install_dir/elasticsearch-5.0.0/config/elasticsearch.yml"
done
#	echo -e "\e[1;31m ---解压安装kibana--- \e[0m"
#	for es_nodes in ${es5_nodes[*]}
#	do
#		tar xzf /opt/kibana-5.0.0-linux-x86_64.tar.gz -C /opt
#		scp -rp /opt/kibana-5.0.0-linux-x86_64 root@$es_nodes:$es5_install_dir > /dev/null
#		ssh $es_nodes -n "chown -R govnetes.govnetes $es5_install_dir/kibana-5.0.0-linux-x86_64"
#		ssh $es_nodes -n "echo '
#server.host: "$es_nodes"
#xpack.security.enabled: false
#' >> $es5_install_dir/kibana-5.0.0-linux-x86_64/config/kibana.yml"
#		ssh $es_nodes -n "su - govnetes << EOF
#source /home/govnetes/.bash_profile
#/home/govnetes/kibana-5.0.0-linux-x86_64/bin/kibana-plugin install file:///home/govnetes/x-pack-5.0.0.zip
#exit
#EOF
#"		
#		ssh $es_nodes -n "$chownes"
#	done
#	$rmtmpkib
$rmtmpes
for es_nodes in ${es5_nodes[*]}
do
	echo -e "\e[1;31m ---$es_nodes启动es5.0--- \e[0m"
	ssh $es_nodes -n "su - govnetes << EOF
source $userhome/.bash_profile
$es5_install_dir/elasticsearch-5.0.0/bin/elasticsearch -d -p es.pid
exit
EOF
"
#	ssh $es_nodes -n "su - govnetes << EOF
#	nohup $es5_install_dir/kibana-5.0.0-linux-x86_64/bin/kibana > /dev/null 2>&1 &
#	exit
#	EOF
#	"
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
action "安装es5.0完成" /bin/true
echo "================================================="
echo ""
echo -e '\e[1;31m es5.0安装完成后，即可在浏览器输入  http://master ip:9200/_cluster/health?pretty  查看es集群状态"status" : "green"则正常 \e[0m'
  sleep 3
}

