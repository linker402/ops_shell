# cat multi_user_cre.sh
#!/bin/sh
echo ""
echo "------------------------------------------------------------------------------------------------------"
echo "请先更新 /opt/_weihu/_user_cre/multi_user_add.list 文件，更改为本次需要新建的用户信息列表，再运行本程序。"
echo "/opt/_weihu/_user_cre/multi_user_add.list 文件中有格式要求描述。"
echo "-------------------------------------------------------------------------------------------------------"
echo ""

if [ $# -ne 1 ]
then
echo "命令格式如下："
echo "`basename $0` 1"
echo "确认已经更新multi_user_add.list文件，请输入：1 "
exit
fi

if [ $1 -ne 1 ]
then
echo "参数错误！！如确认已经更新multi_user_add.list文件，请输入：1"
echo "命令格式如下："
echo "`basename $0` 1"
exit
fi

cat /dev/null > /tmp/multi_user_add.tmp
cat /opt/_weihu/_user_cre/multi_user_add.list|grep -v "^#"|grep -v "^$"|grep -v "^  *$"|while read id group user name
do
/opt/_weihu/_user_cre/user_cre.sh ${id} ${group} ${user} ${name}
cat /tmp/user_cre.tmp >> /tmp/multi_user_add.tmp
done

echo "脚本已经成功运行，/tmp/multi_user_add.tmp 文件中已经生成本次添加用户的脚本。"
echo "请仔细检查脚本内容是否正确，再sh /tmp/multi_user_add.tmp运行增加用户。"