# cat multi_user_cre.sh
#!/bin/sh
echo ""
echo "------------------------------------------------------------------------------------------------------"
echo "���ȸ��� /opt/_weihu/_user_cre/multi_user_add.list �ļ�������Ϊ������Ҫ�½����û���Ϣ�б������б�����"
echo "/opt/_weihu/_user_cre/multi_user_add.list �ļ����и�ʽҪ��������"
echo "-------------------------------------------------------------------------------------------------------"
echo ""

if [ $# -ne 1 ]
then
echo "�����ʽ���£�"
echo "`basename $0` 1"
echo "ȷ���Ѿ�����multi_user_add.list�ļ��������룺1 "
exit
fi

if [ $1 -ne 1 ]
then
echo "�������󣡣���ȷ���Ѿ�����multi_user_add.list�ļ��������룺1"
echo "�����ʽ���£�"
echo "`basename $0` 1"
exit
fi

cat /dev/null > /tmp/multi_user_add.tmp
cat /opt/_weihu/_user_cre/multi_user_add.list|grep -v "^#"|grep -v "^$"|grep -v "^  *$"|while read id group user name
do
/opt/_weihu/_user_cre/user_cre.sh ${id} ${group} ${user} ${name}
cat /tmp/user_cre.tmp >> /tmp/multi_user_add.tmp
done

echo "�ű��Ѿ��ɹ����У�/tmp/multi_user_add.tmp �ļ����Ѿ����ɱ�������û��Ľű���"
echo "����ϸ���ű������Ƿ���ȷ����sh /tmp/multi_user_add.tmp���������û���"