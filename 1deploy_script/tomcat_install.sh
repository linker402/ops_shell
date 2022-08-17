#cat tomcat_install.sh
#!/bin/sh
#!/usr/bin/expect  -f
################################################
# 这个脚本是在指定节点安装tomcat。
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

#Install the tomcat
installTomcat(){
echo "============指定节点安装tomcat=============="
echo "============apache-tomcat-8.5.16.tar.gz需上传到/opt目录=============="
tomcat_dir=`cat ${file_name} | grep tomcat_dir`
tomcat_dir=${tomcat_dir#*=} 
tomcat_user=`cat ${file_name} | grep tomcat_user`
tomcat_user=${tomcat_user#*=} 
tomcat_node=`cat ${file_name} | grep tomcat_node` 
tomcat_node=${tomcat_node#*=} 
rmtmptomcat="rm -rf /opt/apache-tomcat-8.5.16"  
ssh $tomcat_node "id $tomcat_user"
if [ $? -ne 0 ]  
then 
ssh $tomcat_node "useradd -d /home/tomcat $tomcat_user > /dev/null "
ssh $tomcat_node "echo 'tomcat' \|passwd --stdin $tomcat_user > /dev/null"
fi
echo -e "\e[1;31m ---解压tomcat安装包--- \e[0m"
tar xzf /opt/apache-tomcat-8.5.16.tar.gz -C /opt
check
scp -rp /opt/apache-tomcat-8.5.16 $tomcat_node:$tomcat_dir > /dev/null
echo -e "\e[1;31m ---修改tomcat配置--- \e[0m"
ssh $tomcat_node "sed -i '2 a\export JAVA_HOME=\/usr\/java\/jdk1.7.0_79' $tomcat_dir/apache-tomcat-8.5.16/bin/catalina.sh"
ssh $tomcat_node "sed -i '3 a\export JRE_HOME=\/usr\/java\/jdk1.7.0_79\/jre'  $tomcat_dir/apache-tomcat-8.5.16/bin/catalina.sh"
ssh $tomcat_node "sed -i '4 a\JAVA_OPTS=\"-server -Xms1024m -Xmx2048m -XX:PermSize=512M -XX:MaxNewSize=1024m -XX:MaxPermSize=512m -Djava.awt.headless=true\"' $tomcat_dir/apache-tomcat-8.5.16/bin/catalina.sh"
check
#ssh $tomcat_node "echo '
#JAVA_OPTS="\$JAVA_OPTS -server -Xms1024m -Xmx2048m -XX:PermSize=512M -XX:MaxNewSize=1024m"
#' >> $tomcat_dir/apache-tomcat-8.5.16/bin/catalina.sh"
$rmtmptomcat
echo -e "\e[1;31m ---$tomcat_node启动tomcat服务--- \e[0m"
ssh $tomcat_node $tomcat_dir/apache-tomcat-8.5.16/bin/startup.sh
check
sleep 10
echo -e "\e[1;31m ---查看$tomcat_node tomcat是否启动成功，8080端口是否监听--- \e[0m"
ssh $tomcat_node "netstat -an | grep 8080"
action "tomcat安装完成" /bin/true
echo "================================================="
echo ""
echo -e "\e[1;31m tomcat安装完成后，即可在浏览器输入  http://$tomcat_node:8080 打开tomcat主页 \e[0m"
  sleep 3
}
