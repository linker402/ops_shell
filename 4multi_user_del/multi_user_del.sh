#!/bin/sh
#########################################################################################################
#���м���û��ű��󣬿ɵ�֪�����ϵ��û��Ƿ���ڡ��粻���ڣ�����ɾ�������¸���host.list��user.list��
#########################################################################################################
echo "���ݼ���û��ű�������¸���host.list��user.list.���Ѹ���������:Y/y��������˳�"
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
        echo "ssh ${server} \"cat /etc/passwd | grep ${username} >/dev/null 2>&1 && echo ${server} ${username}������ || echo ${server} ${username}�ѱ�ɾ��\"" >> /opt/_weihu/_user_check_del/user_check_again.tmp
        echo "ssh ${server} \"if [ ! -d ${user_home} ] && [ -d ${user_home}_bak_`date +%Y-%m` ];then
        echo \" ${server} ${user_home}�Ѹ���Ϊ${user_home}_bak_`date +%Y-%m` \"
        else 
        echo \" ${server} ${user_home}�����ڣ�δ���� \"
        fi\"" >> /opt/_weihu/_user_check_del/user_check_again.tmp
   done
done
echo "�ű����гɹ�������ɾ���û��ű�/opt/_weihu/_user_check_del/user_del.tmp"
echo "�ű����гɹ��������ٴμ���û��ű�/opt/_weihu/_user_check_del/user_check_again.tmp"
echo "����ϸ���ű������Ƿ���ȷ����sh /opt/_weihu/_user_check_del/user_del.tmp����ɾ���û�"
echo "����ϸ���ű������Ƿ���ȷ����sh /opt/_weihu/_user_check_del/user_check_again.tmp���м���û��Ƿ�ɾ������Ŀ¼�Ƿ����"
else
echo "���ȸ���host.list��user.list�������нű�"
fi