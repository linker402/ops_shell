#!/bin/sh
if [ $# -ne 4 ]
then
echo "`basename $0` �ʺ�ID    ����(��ɫ)    �û��ʺ�    �û�ʵ�� "
echo "������������!"
exit
fi

id=$1
user_group=$2
user_account=$3
user_name=$4

cat /dev/null > /tmp/user_cre.tmp
cat /dev/null > /tmp/host.list
cat /opt/_weihu/_user_cre/user_cre_host.list|grep -v "^#"|grep -v "^$"|grep -v "^  *$" >> /tmp/host.list
exec 3</tmp/host.list;while read -u3 r_host user_host_home
do
echo "ssh ${r_host} \"useradd  -u ${id}  -g ${user_group}  -G ${user_group} -c ${user_name}   -d  /${user_host_home}/${user_group}/${user_account}  ${user_account}\"" >> /tmp/user_cre.tmp
echo "ssh ${r_host} \"echo Gmcc@123 | passwd --stdin ${user_account}\"" >> /tmp/user_cre.tmp
done
echo "���гɹ��󣬻����ɽ����û��Ľű���/tmp/user_cre.tmp�У�����/tmp/user_cre.tmp�����ݣ�Ȼ��ִ��"