#cat cm_install.sh
#!/bin/sh
################################################
# 这个脚本是在主节点安装clouedra manager服务端。
# 在slave节点安装cloudera manager客户端。
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

#Install the Cloudera Manager
installCM(){
echo "============所有节点安装CM并启动=============="
echo "============脚本用到的安装包cloudera-manager-el6-cm5.10.2_x86_64.tar.gz，mysql-connector-java-5.1.35.jar需上传到/opt目录=============="
echo "============脚本用到的安装包CDH-5.10.2-1.cdh5.10.2.p0.5-el6.parcel，CDH-5.10.2-1.cdh5.10.2.p0.5-el6.parcel.sha，manifest.json需上传到/opt目录=============="
echo "============脚本用到的安装包KAFKA-0.8.2.0-1.kafka1.3.0.p0.29-el6.parcel，KAFKA-0.8.2.0-1.kafka1.3.0.p0.29-el6.parcel.sha需上传到/opt目录=============="
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=} 
slave_nodes=`cat ${file_name} | grep slave_nodes` 
slave_nodes=${slave_nodes#*=} 
this_host=`hostname -s`
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
echo -e "\e[1;31m ---新建cloudera-scm用户--- \e[0m"
for cmuser_nodes in ${all_nodes[*]}
do
  	ssh $cmuser_nodes 'useradd  --home=/opt/cm-5.10.2 --no-create-home --shell=/bin/false --comment "Cloudera SCM User" cloudera-scm'  > /dev/null 2>&1
	ssh $cmuser_nodes 'mkdir -p /usr/share/java/' > /dev/null 2>&1
	scp /opt/mysql-connector-java-5.1.35.jar $cmuser_nodes:/usr/share/java/mysql-connector-java.jar > /dev/null
done
check
echo -e "\e[1;31m ---解压安装cloudera-scm-server--- \e[0m"
if test "$master_nodes" == "$this_host";then
tar xzf /opt/cloudera-manager-el6-cm5.10.2_x86_64.tar.gz -C /opt/
cp /opt/mysql-connector-java-5.1.35.jar /opt/cm-5.10.2/share/cmf/lib/	
/opt/cm-5.10.2/share/cmf/schema/scm_prepare_database.sh mysql cm -hlocalhost -uroot -p123456 --scm-host localhost scm scm scm
sed -i "s/server_host\=localhost/server_host\=$master_nodes/g" /opt/cm-5.10.2/etc/cloudera-scm-agent/config.ini
echo "cloudera_mysql_connector_jar=/opt/cm-5.10.2/share/cmf/lib/mysql-connector-java-5.1.35.jar" >> /opt/cm-5.10.2/etc/cloudera-scm-agent/config.ini
cp /opt/CDH-5.10.2* /opt/cloudera/parcel-repo
cp /opt/KAFKA-0.8.2.0* /opt/cloudera/parcel-repo
cp /opt/KUDU-1.3.0-1* /opt/cloudera/parcel-repo
cp /opt/manifest.json /opt/cloudera/parcel-repo
echo -e "\e[1;31m ---同步cloudera-scm-agent--- \e[0m"
for cmagent_nodes in ${slave_nodes[*]}
do
	scp -r /opt/cm-5.10.2 root@$cmagent_nodes:/opt/  > /dev/null
done
check
echo -e "\e[1;31m ---启动cloudera-scm-server--- \e[0m"
/opt/cm-5.10.2/etc/init.d/cloudera-scm-server start
check
sleep 2
cp /opt/cm-5.10.2/etc/init.d/cloudera-scm-server /etc/init.d/cloudera-scm-server
sed -i 's/CMF_DEFAULTS\=\${CMF_DEFAULTS:-\/etc\/default}/CMF_DEFAULTS\=\${CMF_DEFAULTS:-\/opt\/cm-5.10.2\/etc\/default\}/g' /etc/init.d/cloudera-scm-server
chkconfig cloudera-scm-server on
echo -e "\e[1;31m ---启动cloudera-scm-agent--- \e[0m"
for cmagent_nodes in ${all_nodes[*]}
do
	ssh $cmagent_nodes -n "mkdir /opt/cm-5.10.2/run/cloudera-scm-agent"
	ssh $cmagent_nodes -n "chown -R cloudera-scm:cloudera-scm /opt/cm-5.10.2"
	ssh $cmagent_nodes -n "kill -9 $(pgrep -f supervisord) > /dev/null 2>&1" 
	ssh $cmagent_nodes -n "/opt/cm-5.10.2/etc/init.d/cloudera-scm-agent start"
	sleep 2
	ssh $cmagent_nodes -n "cp /opt/cm-5.10.2/etc/init.d/cloudera-scm-agent /etc/init.d/cloudera-scm-agent"
	ssh $cmagent_nodes -n "sed -i 's/CMF_DEFAULTS\=\${CMF_DEFAULTS:-\/etc\/default}/CMF_DEFAULTS\=\${CMF_DEFAULTS:-\/opt\/cm-5.10.2\/etc\/default\}/g' /etc/init.d/cloudera-scm-agent"
	ssh $cmagent_nodes -n "chkconfig cloudera-scm-agent on"
done
check
for cm_nodes in ${all_nodes[*]}
do
	ssh $cm_nodes "chown -R cloudera-scm.cloudera-scm /opt/cm-5.10.2"
done
check
else
  echo "请在Master节点运行安装!"
fi
check
echo -e "\e[1;31m ---查看cloudera-scm-server进程状态--- \e[0m"
/etc/init.d/cloudera-scm-server status
action "主节点cm-server安装完成" /bin/true
echo "================================================="
for cmagent_nodes in ${all_nodes[*]}
do
echo -e "\e[1;31m ---查看$cmagent_nodes节点cloudera-scm-agent进程状态--- \e[0m"
ssh $cmagent_nodes -n "/etc/init.d/cloudera-scm-agent status"
done
check
action "slave节点cm-agent安装完成" /bin/true
echo "================================================="
echo ""
echo -e "\e[1;31m cm安装完成后，即可在谷歌浏览器输入 http://$master_nodes:7180 进入CDH安装界面，用户和密码均为admin \e[0m"
  sleep 3
}
