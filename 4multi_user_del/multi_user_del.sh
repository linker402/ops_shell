#!/bin/sh
#########################################################################################################
#运行检查用户脚本后，可得知主机上的用户是否存在。如不存在，则不用删。请重新更新host.list和user.list。
#########################################################################################################
echo "根据检查用户脚本结果重新更新host.list和user.list.如已更新请输入:Y/y，任意键退出"
read input
if [ ${input} = "Y" ] || [ ${input} = "y" ]
then
cat /dev/null > /opt/_weihu/_user_check_del/user_del.tmp
cat /dev/null > /opt/_weihu/_user_check_del/user_check_again.tmp
cat /dev/null > /tmp/hostback.list
cat /dev/null > /tmp/userback.list
cat /opt/_weihu/_user_check_del/host.list | grep -v "^#"|grep -v "^$"|grep -v "^  *$" >/tmp/hostback.list
exec 3</tmp/hostback.list;while read -u3 server
do
cat /opt/_weihu/_user_check_del/user.list | grep -v "^#"|grep -v "^$"|grep -v "^  *$" >/tmp/userback.list
exec 4</tmp/userback.list;while read -u4 username
   do
        user_home=`ssh $server "cat /etc/passwd | grep ${username} " | awk -F: '{print $6}'`
        echo "ssh ${server} \"cp -r ${user_home} ${user_home}_bak_`date +%Y-%m`\"" >> /opt/_weihu/_user_check_del/user_del.tmp
        echo "ssh ${server} \"userdel -r ${username}\"" >> /opt/_weihu/_user_check_del/user_del.tmp
        echo "ssh ${server} \"cat /etc/passwd | grep ${username} >/dev/null 2>&1 && echo ${server} ${username}还存在 || echo ${server} ${username}已被删除\"" >> /opt/_weihu/_user_check_del/user_check_again.tmp
        echo "ssh ${server} \"if [ ! -d ${user_home} ] && [ -d ${user_home}_bak_`date +%Y-%m` ];then
        echo \" ${server} ${user_home}已改名为${user_home}_bak_`date +%Y-%m` \"
        else 
        echo \" ${server} ${user_home}还存在，未改名 \"
        fi\"" >> /opt/_weihu/_user_check_del/user_check_again.tmp
   done
done
echo "脚本运行成功，生成删除用户脚本/opt/_weihu/_user_check_del/user_del.tmp"
echo "脚本运行成功，生成再次检查用户脚本/opt/_weihu/_user_check_del/user_check_again.tmp"
echo "请仔细检查脚本内容是否正确，再sh /opt/_weihu/_user_check_del/user_del.tmp运行删除用户"
echo "请仔细检查脚本内容是否正确，再sh /opt/_weihu/_user_check_del/user_check_again.tmp运行检查用户是否删除，家目录是否改名"
else
echo "请先更新host.list和user.list，再运行脚本"
fi