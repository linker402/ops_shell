#!/bin/sh
echo "���ȸ���host.list��user.list�����Ѹ���������:Y/y��������˳�"
read input
if [ ${input} = "Y" ] || [ ${input} = "y" ]
then
cat /dev/null > /opt/_weihu/_user_check_del/user_check.tmp
cat /opt/_weihu/_user_check_del/host.list | grep -v "^#"|grep -v "^$"|grep -v "^  *$" | while read server
do
cat /opt/_weihu/_user_check_del/user.list | grep -v "^#"|grep -v "^$"|grep -v "^  *$" | while read username
   do
        echo "sudo ssh ${server} \"id ${username} >/dev/null 2>&1 && echo ${server} ${username}���� || echo ${server} ${username}������\"" >> /opt/_weihu/_user_check_del/user_check.tmp
   done
done
echo "�ű��ɹ����У����ɼ���û��ű�/opt/_weihu/_user_check_del/user_check.tmp"
echo "����ϸ���ű������Ƿ���ȷ����sh /opt/_weihu/_user_check_del/user_check.tmp���м���û��Ƿ����"
else
echo "���ȸ���host.list��user.list�������нű�"
fi