#!/bin/sh
while :
do
PR_DIR="$(cd `dirname $0`; pwd)"
#FTP服务器目录
vFetchDir=/
#本地文件目录
vLocalDir=/mnt/16aaa/avro_2
#FTP服务器信息
vIP=192.168.1.111
vUser=xzpt
vPasswd=xzpt


FETCH_FILE_LIST()
{
  vDir=$1
    ftp -n -v ${vIP} << EOF
      user ${vUser} ${vPasswd}
      binary
      hash
      prompt
      dir $vDir/*.avro
      close
      bye
EOF
}

GET_DELETE_FILE()
{
   vDir=$1
   vFileName=$2
    ftp -n -v ${vIP} << EOF
      user ${vUser} ${vPasswd}
      binary
      hash
      prompt
      cd ${vDir}
      lcd ${vLocalDir}
      mget ${vFileName}
      delete ${vFileName}
      close
      bye
EOF
}

FETCH_FILE_LIST ${vFetchDir} > $PR_DIR/fetch_file_list.tmp
grep "avro$" $PR_DIR/fetch_file_list.tmp|awk '{print $NF}' > $PR_DIR/fetch_file.list


if [ `cat $PR_DIR/fetch_file.list|wc -l` -eq 0 ];then
  echo `date`
  echo "ftp目录下无文件"
#  continue
else
  cat $PR_DIR/fetch_file.list|while read vFile
  do
    GET_DELETE_FILE ${vFetchDir} ${vFile}
  done
  echo `date`
  echo "文件已经采集到本地并且远端文件已经被删除,请检查,文件名分别是：`grep "avro$" $PR_DIR/fetch_file_list.tmp|awk '{print $NF}'|xargs`"
fi
sleep 5m
done