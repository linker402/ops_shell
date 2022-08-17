#cat jdk7_install.sh
#!/bin/sh
################################################
# 这个脚本功能是自动安装jdk1.7
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

#Install the jdk1.7
installJdk7(){
echo "============所有节点安装jdk1.7============"
echo "============脚本用到的安装包是jdk-7u79-linux-x64.gz需上传到/opt目录============"
jdk_dir=`cat ${file_name} | grep jdk_dir`
jdk_dir=${jdk_dir#*=}
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
echo -e "\e[1;31m ---卸载系统自带openjdk--- \e[0m" 
for jdk7_nodes in ${all_nodes[*]}
do

	ssh $jdk7_nodes "rpm -qa | grep ^java" | while read line;
	do  
		ssh $jdk7_nodes -n "rpm -e $line"
	done
done
check
echo -e "\e[1;31m ---建立jdk安装目录--- \e[0m" 
for jdk7_nodes in ${all_nodes[*]}
do
	ssh $jdk7_nodes [ -d "$jdk_dir" ]
	if [ $? -ne 0 ];then 
		ssh $jdk7_nodes mkdir $jdk_dir
	fi
done
check
echo -e "\e[1;31m ---添加环境变量--- \e[0m"
for jdk7_nodes in ${all_nodes[*]}
do
	tar xzf /opt/jdk-7u79-linux-x64.gz -C $jdk_dir
	scp -rp $jdk_dir/jdk1.7.0_79 root@$jdk7_nodes:$jdk_dir/ > /dev/null
	if ssh $jdk7_nodes -n 'grep -q "JAVA_HOME=/usr/java/jdk1.7.0_79" /etc/profile';then
		continue
	else
	ssh $jdk7_nodes -n 'echo "
JAVA_HOME=/usr/java/jdk1.7.0_79
PATH="\$JAVA_HOME/bin:\$PATH"
CLASSPATH=.:"\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar"
" >> /etc/profile'
	fi
done
check
for jdk7_nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$jdk7_nodes节点jdk版本--- \e[0m"
	ssh $jdk7_nodes -n "source /etc/profile"
	ssh $jdk7_nodes -n "$jdk_dir/jdk1.7.0_79/bin/java -version"
done
check
action "==========安装jdk1.7完成==========" /bin/true
echo "================================================="
echo ""
  sleep 3
}
