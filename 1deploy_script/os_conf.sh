#cat os_conf.sh
#!/bin/sh
#!/usr/bin/expect
################################################
# This script is os configuration scripts
# version:1.0 lichengyong
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

#config local-yum
ISO=`ls /opt/CentOS-*-x86_64-bin-DVD1.iso`
localyum() {
echo "========配置本地YUM软件源========"
if [ ! -f "$ISO" ];then
	echo -e "\e[1;33m ---请先上传$ISO到/opt目录下--- \e[0m"
	sleep 3
	break
else
   mkdir /mnt/iso > /dev/null 2>&1
   mount -o loop $ISO /mnt/iso > /dev/null 2>&1
   rm -rf /etc/yum.repos.d/*
   echo "
[base]
name=CentOS
baseurl=file:///mnt/iso
enabled=1
gpgcheck=0
" >> /etc/yum.repos.d/os.repo
    rm -rf /var/run/yum.pid
    yum install httpd -y > /dev/null
	sed -i 's/"Listen 80"/"Listen 8008"/g' /etc/httpd/conf/httpd.conf
	chkconfig httpd on
	service httpd restart 
	check
	echo -e "\e[1;31m ---拷贝文件到http目录，请等待数秒--- \e[0m"
	cp -Ru /mnt/iso /var/www/html/ > /dev/null
	check
	service iptables stop
fi
action "==========配置local-yum完成==========" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#Configure SSH not password login.
autoSsh(){
echo "========配置root用户ssh免密码登录========"
chmod +x ./*.sh > /dev/null
yum install -y gcc > /dev/null
sleep 1
tar xzf /opt/sshpass-1.06.tar.gz -C /opt/
cd /opt/sshpass-1.06
./configure > /dev/null
make > /dev/null
make install > /dev/null
check
cd -
ssh_dir=~/.ssh
id_res_pub=~/.ssh/id_rsa.pub 
auth_file=~/.ssh/authorized_keys
all_nodes=`cat ${file_name} | grep all_nodes`
all_nodes=${all_nodes#*=}
slave_nodes=`cat ${file_name} | grep slave_nodes`
slave_nodes=${slave_nodes#*=}
root_pd=`cat ${file_name} | grep root_pd`
root_pd=${root_pd#*=}
if [ ! -d "$ssh_dir" ];then  
	mkdir $ssh_dir
fi
if [ ! -f "$id_res_pub" ];then  
	ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa > /dev/null
fi
for ssh_nodes in ${slave_nodes[*]} 
do
	/usr/local/bin/sshpass -p $root_pd ssh $ssh_nodes -o StrictHostKeyChecking=no "rm -rf $ssh_dir"
done
for ssh_nodes in ${slave_nodes[*]} 
do
	/usr/local/bin/sshpass -p $root_pd ssh $ssh_nodes -o StrictHostKeyChecking=no "mkdir $ssh_dir"
	/usr/local/bin/sshpass -p $root_pd ssh $ssh_nodes -o StrictHostKeyChecking=no "touch $auth_file"
done	
for ssh_nodes in ${all_nodes[*]} 
do
	/usr/local/bin/sshpass -p $root_pd ssh ${ssh_nodes} -o StrictHostKeyChecking=no "cat /dev/null > $auth_file"
	cat ~/.ssh/id_rsa.pub | /usr/local/bin/sshpass -p $root_pd ssh ${ssh_nodes} -o StrictHostKeyChecking=no 'cat >> ~/.ssh/authorized_keys' 
	/usr/local/bin/sshpass -p $root_pd ssh $ssh_nodes -o StrictHostKeyChecking=no "chmod 755 $ssh_dir;chmod 600 $auth_file"
	/usr/local/bin/sshpass -p $root_pd ssh $ssh_nodes -o StrictHostKeyChecking=no "setenforce 0"
done
for ssh_nodes in ${all_nodes[*]} 
do
	echo -e "\e[1;31m ---测试免密码登录，此时不需要输入密码获取$ssh_nodes主机名代表成功--- \e[0m"
	ssh $ssh_nodes -n hostname
    scp /etc/hosts $ssh_nodes:/etc/ >> /dev/null
done
rm -rf /opt/sshpass-1.06
action "==========配置root用户ssh免密码登录完成==========" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#Close Selinux and Iptables
initFirewall(){
echo "==========所有节点禁用SELINUX及关闭防火墙=========="
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
for fire_nodes in ${all_nodes[*]}
do
	cp /etc/selinux/config /etc/selinux/config.$(date +%F)
	ssh $fire_nodes -n "/etc/init.d/iptables stop"
	ssh $fire_nodes -n "chkconfig iptables off"
	ssh $fire_nodes -n "sed -i 's/SELINUX\=enforcing/SELINUX\=disabled/g' /etc/selinux/config"
	ssh $fire_nodes -n "sed -i 's/SELINUX\=permissive/SELINUX\=disabled/g' /etc/selinux/config"
	ssh $fire_nodes -n "setenforce 0"
done
for fire_nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$fire_nodes节点防火墙状态和selinux--- \e[0m"
	ssh $fire_nodes -n "/etc/init.d/iptables status"
	ssh $fire_nodes -n "grep SELINUX=disabled /etc/selinux/config"
done

action "==========禁用selinux及关闭防火墙完成==========" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#Config Yum slave os.repo
configYum(){
echo "================所有节点更新YUM源=================="
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=}
for yum_nodes in ${all_nodes[*]} 
do
	ssh $yum_nodes -n "rm -rf /etc/yum.repos.d/*"
	ssh $yum_nodes -n "echo '
[remote]
name=CentOS
baseurl=http://$master_nodes:8008/iso
enabled=1
gpgcheck=0
' >> /etc/yum.repos.d/os.repo"
done
for yum_nodes in ${all_nodes[*]} 
do
	echo -e "\e[1;31m ---查看$yum_nodes节点yum list是否可用--- \e[0m"
	ssh $yum_nodes -n "yum list" > /dev/null
	check
done
action "==========所有节点更新YUM源完成=========="  /bin/true
echo "================================================="
echo ""
  sleep 3
}

#Charset zh_CN.UTF-8
initI18n(){
echo "================所有节点配置中文字符集================="
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
for char_nodes in ${all_nodes[*]}
do
	cp /etc/sysconfig/i18n /etc/sysconfig/i18n.$(date +%F)
	
	ssh $char_nodes -n "echo '
LANG=\"zh_CN.UTF-8\" 
SUPPORTED=\"zh_CN.GB18030:zh_CN:zh:en_US.UTF-8:en_US:en\" 
SYSFONT=\"latarcyrheb-sun16\"
' > /etc/sysconfig/i18n"
	ssh $char_nodes -n "source /etc/sysconfig/i18n"
done
for char_nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$char_nodes节点/etc/sysconfig/i18n文件--- \e[0m"
	ssh $char_nodes -n "grep LANG /etc/sysconfig/i18n"
done
action "==========更改字符集zh_CN.UTF-8完成==========" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#time sync
syncSysTime(){
echo "================配置时间同步server和client================"
master_nodes=`cat ${file_name} | grep master_nodes` 
master_nodes=${master_nodes#*=}
slave_nodes=`cat ${file_name} | grep slave_nodes` 
slave_nodes=${slave_nodes#*=}
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
for ntp_nodes in ${all_nodes[*]}
do 
	ssh $ntp_nodes -n "yum -y install ntp" > /dev/null
done
cp /etc/ntp.conf /etc/ntp.conf.$(date +%F)
cat /dev/null > /etc/ntp.conf
echo "
driftfile /var/lib/ntp/drift
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict -6 ::1
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
server 127.127.1.0
fudge  127.127.1.0 stratum 10
" >> /etc/ntp.conf
/etc/init.d/ntpd restart;chkconfig ntpd on
for ntp_slave_nodes in ${slave_nodes[*]}
do
	ssh $ntp_slave_nodes -n "/etc/init.d/ntpd stop"
	sleep 2
	ssh $ntp_slave_nodes -n "ntpdate $master_nodes"
	ssh $ntp_slave_nodes -n "cat /dev/null > /etc/ntp.conf"
	ssh $ntp_slave_nodes -n "echo '
driftfile /var/lib/ntp/drift
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict -6 ::1
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
server $master_nodes
' >> /etc/ntp.conf"
	ssh $ntp_slave_nodes -n "/etc/init.d/ntpd start;chkconfig ntpd on"
done
for ntp_nodes in ${all_nodes[*]}
do 
	echo -e "\e[1;31m ---查看$ntp_nodes节点时间是否一致--- \e[0m"
	ssh $ntp_nodes -n "date"
done
for ntp_nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$ntp_nodes节点ntp.conf文件--- \e[0m"
	ssh $ntp_nodes -n "grep  server /etc/ntp.conf"
done
for ntp_nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$ntp_nodes节点ntpd进程状态--- \e[0m"
	ssh $ntp_nodes -n "/etc/init.d/ntpd status"
done
action "==========配置时间同步完成==========" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#install tools
#initTools(){
#  echo "#####install tools#####"
#  yum groupinstall base -y
#  yum groupinstall core -y
#  yum groupinstall development libs -y
#  yum groupinstall development tools -y
#  echo "install toos complete."
#  sleep 1
#}
  
#Adjust the file descriptor(limits.conf)
initLimits(){
echo "===============所有节点系统参数优化===================="
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
for limit_nodes in ${all_nodes[*]}
do 
	cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F)
	if ssh $limit_nodes -n 'grep -q "*       hard    memlock  unlimited" /etc/security/limits.conf';then
	   continue
	else
		ssh $limit_nodes -n 'echo "
*       soft    nofile  65536
*       hard    nofile  65536
*       soft    nproc   131072
*       hard    nproc   131072
*       soft    memlock  unlimited
*       hard    memlock  unlimited
govnetapp       soft    nofile  65536
govnetapp       hard    nofile  65536
govnetapp       soft    nproc   131072
govnetapp       hard    nproc   131072
govnetes       soft    nofile  65536
govnetes       hard    nofile  65536
govnetes       soft    nproc   131072
govnetes       hard    nproc   131072
" >> /etc/security/limits.conf'
	fi
done
for limit_nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$limit_nodes节点limits.conf文件--- \e[0m"
	ssh $limit_nodes -n "tail -11 /etc/security/limits.conf"
done
action "==========limits系统参数优化完成==========" /bin/true
echo "================================================="
echo ""
sleep 3
}
 
#Optimizing the system kernel
initSysctl(){
echo "================所有节点内核参数优化====================="
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
for sysctl_nodes in ${all_nodes[*]}
do 
	cp /etc/sysctl.conf /etc/sysctl.conf.$(date +%F)
	cp /etc/rc.local /etc/rc.local.$(date +%F) 
	if ssh $sysctl_nodes -n 'grep -q "modprobe bridge" /etc/rc.local';then
	   continue
	else
		ssh $sysctl_nodes -n 'echo "modprobe nf_conntrack">> /etc/rc.local'
		ssh $sysctl_nodes -n 'echo "modprobe bridge">> /etc/rc.local'
	fi
	if ssh $sysctl_nodes -n 'grep -q "vm.max_map_count = 262144" /etc/sysctl.conf';then
	   continue
	else
		ssh $sysctl_nodes -n 'echo "
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_syn_backlog = 262144
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 2
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_max_orphans = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_no_metrics_save = 1
net.core.rmem_default = 4194304
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 262144
net.ipv4.icmp_echo_ignore_broadcasts = 1
vm.max_map_count = 262144
" >> /etc/sysctl.conf'
	fi
	if ssh $sysctl_nodes -n 'grep -q "vm.swappiness = 0" /etc/sysctl.conf';then
	   continue
	else
		ssh $sysctl_nodes -n 'echo vm.swappiness = 0 >> /etc/sysctl.conf'
	fi
done
for sysctl_nodes in ${all_nodes[*]}
do 
	echo -e "\e[1;31m ---查看$sysctl_nodes节点sysctl.conf文件--- \e[0m"
	ssh $sysctl_nodes -n "modprobe nf_conntrack"
	ssh $sysctl_nodes -n "modprobe bridge"
	ssh $sysctl_nodes -n "sysctl -p"
done
for sysctl_nodes in ${all_nodes[*]}
do 
	echo -e "\e[1;31m ---查看$sysctl_nodes节点rc.local文件--- \e[0m"
	ssh $sysctl_nodes -n "tail -2 /etc/rc.local"
done
action "==========内核调优完成==========" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#Transparent large pages are forbidden
initPage(){
echo "================所有节点禁止透明大页====================="
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
for page_nodes in ${all_nodes[*]}
do 
	if ssh $page_nodes -n 'grep -q "echo neve" /etc/rc.local';then
	   continue
	else
		ssh $page_nodes -n 'echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag'
		ssh $page_nodes -n 'echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >> /etc/rc.local'
		ssh $page_nodes -n 'echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled'
		ssh $page_nodes -n 'echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled" >> /etc/rc.local'
	fi
done
for page_nodes in ${all_nodes[*]}
do 
	echo -e "\e[1;31m ---查看$page_nodes节点rc.local文件--- \e[0m"
	ssh $page_nodes -n "tail -2 /etc/rc.local"
done
action "==========禁止透明大页调优完成===========" /bin/true
echo "================================================="
echo ""
  sleep 3
}

#add user
addUser(){
echo "===================所有节点新建用户======================"
echo "===================请新建gonetapp用户======================"
#add user
while true
do  
    read -p "请输入新用户名:" name
    NAME=`awk -F':' '{print $1}' /etc/passwd|grep -wx $name 2>/dev/null|wc -l`
    if [ ${#name} -eq 0 ];then
       echo "用户名不能为空，请重新输入。"
       continue
    elif [ $NAME -eq 1 ];then
       echo "用户名已存在，请重新输入。"
       continue
    fi
all_nodes=`cat ${file_name} | grep all_nodes` 
all_nodes=${all_nodes#*=} 
for adduser_nodes in ${all_nodes[*]}
do 
	ssh $adduser_nodes -n "useradd $name"
done
break
done

#create password
while true
do
    read -p "为 $name 创建一个密码:" pass1
    if [ ${#pass1} -eq 0 ];then
       echo "密码不能为空，请重新输入。"
       continue
    fi
    read -p "请再次输入密码:" pass2
    if [ "$pass1" != "$pass2" ];then
       echo "两次密码输入不相同，请重新输入。"
       continue
    fi
for adduser_nodes in ${all_nodes[*]}
do 
	ssh $adduser_nodes -n "echo '$pass2' |passwd --stdin $name"
done
break
done

for adduser_nodes in ${all_nodes[*]}
do
	echo -e "\e[1;31m ---查看$adduser_nodes节点用户建立情况--- \e[0m"
	ssh $adduser_nodes -n "id $name"
done

action "==========用户建立完成==========" /bin/true
echo "================================================="
echo ""
sleep 3
}
