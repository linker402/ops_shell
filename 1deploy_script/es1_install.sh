#cat es1_install.sh
#!/bin/sh
################################################
# 这个脚本是在指定节点安装elasticsearch1.4.2集群。
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

#Install the elasticsearch1.4
installEs1(){
echo "============指定节点安装elasticsearch1.4.2=============="
echo "============脚本用到的安装包elasticsearch.zip需放在/opt目录下=============="
rpm --import /etc/pki/rpm-gpg/RPM* > /dev/null
yum install -y expect > /dev/null
sleep 1
#安装目录  
es1_install_dir=`cat ${file_name} | grep es1_install_dir`  
es1_install_dir=${es1_install_dir#*=}  
#es数据目录  
es1_data_dirs=`cat ${file_name} | grep es1_data_dirs`  
es1_data_dirs=${es1_data_dirs#*=}  
es1_dir_nu=`echo "$es1_data_dirs"|sed 's/,/ /g'`
#es节点  
es1_nodes=`cat ${file_name} | grep es1_nodes`  
es1_nodes=${es1_nodes#*=}  
es1_nodes_dd=`echo "$es1_nodes"|sed 's/ /,/g'`
es1_nodes_1=`echo "$es1_nodes"|awk '{print $1}'`
es1_nodes_oth=`echo $es1_nodes|awk '{split ($0,a," ")};{for (i=2;i<=NF;i++) print a[i]}' | xargs`
es_log_dir="mkdir -p /var/log/es1/logs"
es_config="${es1_install_dir}/elasticsearch/elasticsearch/config"   
chmodes="chmod +x ${es1_install_dir}/elasticsearch/elasticsearch/bin/service/elasticsearch"
rmtmpes="rm -rf /opt/elasticsearch"  
echo -e "\e[1;31m ---解压安装elasticsearch1.4.2--- \e[0m"
unzip /opt/elasticsearch.zip  -d /opt > /dev/null
for nodes in ${es1_nodes[*]}  
do
	for dirs in ${es1_dir_nu[*]} 
	do 
		ssh $nodes -n "mkdir -p $dirs > /dev/null 2>&1"
	done
done
for nodes in ${es1_nodes[*]}  
do     
	ssh $nodes -n "$es_log_dir  > /dev/null 2>&1"
	scp -rp /opt/elasticsearch root@$nodes:$es1_install_dir > /dev/null
	ssh $nodes -n "sed -i 's/set.default.ES_HEAP_SIZE=1024/set.default.ES_HEAP_SIZE=16384/g' ${es1_install_dir}/elasticsearch/elasticsearch/bin/service/elasticsearch.conf"
	ssh $nodes -n "sed -i 's/cluster.name:\ govdatasearchlocal/cluster.name:\ govnetesv1/g' $es_config/elasticsearch.yml"
	ssh $nodes -n "sed -i 's/index.number_of_shards:\ 5/index.number_of_shards:\ 6/g' $es_config/elasticsearch.yml"
	ssh $nodes -n "echo '

############################ Node ############################
node.name: $nodes
node.master: true
node.data: true
############################ Paths ############################
path.data: ${es1_data_dirs}
path.logs: /var/log/es1/logs
###################### Network And HTTP #######################
network.bind_host: $nodes
network.publish_host: $nodes
network.host: $nodes
transport.tcp.port: 9300
transport.tcp.compress: true
http.port: 9200
http.max_content_length: 100mb
http.enabled: true
########################### Gateway ###########################
gateway.type: local
gateway.recover_after_nodes: 2 
gateway.recover_after_time: 5m
gateway.expected_nodes: 2
########################## Discovery ##########################
discovery.zen.minimum_master_nodes: 1
discovery.zen.ping.timeout: 3s
discovery.zen.ping.multicast.enabled: false
discovery.zen.ping.unicast.hosts: [$es1_nodes_dd]
' >> $es_config/elasticsearch.yml"
done
$rmtmpes
for nodes in ${es1_nodes_oth[*]}  
do 
ssh $nodes "sed -i 's/node.master: true/node.master: false/' $es_config/elasticsearch.yml"
done
check
for nodes in ${es1_nodes[*]}
do
	echo -e "\e[1;31m ---$nodes启动es1.4.2-- \e[0m"
	ssh $nodes -n "$chmodes"
#	ssh $nodes -n "source /etc/profile"
#	ssh $nodes -n "$es1_install_dir/elasticsearch/elasticsearch/bin/service/elasticsearch start"
	./expect_start_es1.sh $nodes $es1_install_dir > /dev/null
	ssh $nodes -n "service iptables stop;chkconfig iptables off"
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
action "安装es1.4完成" /bin/true
echo "================================================="
echo ""
echo -e '\e[1;31m es1.4.2安装完成后，即可在浏览器输入  http://master ip:19200/_cluster/health?pretty  查看es集群状态"status" : "green"则正常 \e[0m'
  sleep 3
}
