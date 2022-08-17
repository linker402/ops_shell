#!/bin/sh
echo "请先更新host.list和user.list。如已更新请输入:Y/y，任意键退出"
read input
if [ ${input} = "Y" ] || [ ${input} = "y" ]
then
cat /dev/null > /opt/_weihu/_user_check_del/user_check.tmp
cat /opt/_weihu/_user_check_del/host.list | grep -v "^#"|grep -v "^$"|grep -v "^  *$" | while read server
do
cat /opt/_weihu/_user_check_del/user.list | grep -v "^#"|grep -v "^$"|grep -v "^  *$" | while read username
   do
        echo "sudo ssh ${server} \"id ${username} >/dev/null 2>&1 && echo ${server} ${username}存在 || echo ${server} ${username}不存在\"" >> /opt/_weihu/_user_check_del/user_check.tmp
   done
done
echo "脚本成功运行，生成检查用户脚本/opt/_weihu/_user_check_del/user_check.tmp"
echo "请仔细检查脚本内容是否正确，再sh /opt/_weihu/_user_check_del/user_check.tmp运行检查用户是否存在"
else
echo "请先更新host.list和user.list，再运行脚本"
fi