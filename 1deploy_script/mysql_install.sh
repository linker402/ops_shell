#cat mysql_install.sh
#!/bin/sh
################################################
# 这个脚本功能是在主节点安装mysql。
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

#Install the mysql
installMysql(){
echo "============主节点安装mysql并配置============"
echo "============脚本用到的安装包是mysql-5.6.14-linux-glibc2.5-x86_64.tar.gz需上传到/opt目录============"
mysql_dir=`cat ${file_name} | grep mysql_dir`
mysql_dir=${mysql_dir#*=} 
mysql_user=`cat ${file_name} | grep mysql_user`
mysql_user=${mysql_user#*=} 
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=} 
this_host=`hostname -s`
echo -e "\e[1;31m ---解压安装mysql，并配置用户和建库--- \e[0m"
for mysql_nodes in ${master_nodes[*]}
do
	if test "$mysql_nodes" == "$this_host";then
		egrep "^mysql" /etc/passwd >& /dev/null  
		if [ $? -ne 0 ]  
		then  
			useradd -r $mysql_user
		fi  
		tar -xzf /opt/mysql-5.6.14-linux-glibc2.5-x86_64.tar.gz -C $mysql_dir
		mv $mysql_dir/mysql-5.6.14-linux-glibc2.5-x86_64 $mysql_dir/mysql
		chown -R mysql.mysql $mysql_dir/mysql
		$mysql_dir/mysql/scripts/mysql_install_db --user=mysql --basedir=$mysql_dir/mysql/ --datadir=$mysql_dir/mysql/data > /dev/null
		cp $mysql_dir/mysql/support-files/mysql.server /etc/rc.d/init.d/mysql
		cp $mysql_dir/mysql/support-files/my-default.cnf /etc/my.cnf
		echo "

character-set-server = utf8mb4
lower_case_table_names = 1
log-error=/var/log/mysql.log
innodb_log_file_size = 256M
	" >> /etc/my.cnf
		chkconfig --add mysql
		chkconfig mysql on
		ln -s $mysql_dir/mysql/bin/mysql /usr/bin/mysql
		/etc/init.d/mysql start
		$mysql_dir/mysql/bin/mysqladmin -u root password 123456
		mysql -uroot -p123456 -e "
use mysql;
update user set password=password('123456') where user='root';
flush privileges;
quit"
		mysql -uroot -p123456 -e "
create database hive DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database amon DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database report DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database activity DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database oozie DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database hue DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database metastore DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create database rman DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
quit"
		mysql -uroot -p123456 -e "
grant all privileges on *.* to 'root'@'%' identified by '123456' with grant option;
flush privileges;
quit"
	else
		echo "请在Master节点运行安装!"
	fi
done
check
echo -e "\e[1;31m ---查看mysql进程状态--- \e[0m"
/etc/init.d/mysql status
check
echo -e "\e[1;31m ---查看mysql建库是否成功--- \e[0m"
echo "show databases;" | mysql -uroot -p123456
check
action "主节点安装mysql完成" /bin/true
echo "================================================="
echo ""
  sleep 3
}
