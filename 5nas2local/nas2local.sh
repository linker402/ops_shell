#!/bin/bash

while :
do
#监控的源目录
SD=/mnt/16fbe83b-392f-11e6-a6dc-00163e0216f8/avro_2/
#监控的目标目录
TD=/tmp/srcAVRO

PR_DIR="$(cd "`dirname "$0"`"/..; pwd)"
DATATYPE_LIST=${PR_DIR}/conf/datatype.list

if [ ! -d erravro ]; then
       mkdir erravro
fi

if [ ! -d zeroavro ]; then
       mkdir zeroavro
fi

cat ${DATATYPE_LIST} | while read file
do
num=`find $TD -type f -name "$file#*" | wc -l`
	if [ $num -lt 100 ]
	then 
	cc=100
	find $SD -type f -name "$file#*" | while read line 
	do      
		if [ $cc -gt $num ]
		then 
			mv $line $TD
			cc=`expr $cc - 1`
		else
			break
		fi
                #错误文件处理 
		filename=`echo ${line} | cut -f6 -d"/"`
                error=$(java -jar ../lib/avro-tools-1.7.6-cdh5.4.2.jar tojson $TD/${filename}  2>&1|grep "Caused by")

                if [ ! -z "${error}"  ]; then
                       echo "Find error file : $TD/${filename}" >> errfile.txt
                       mv $TD/${filename} ./erravro
                fi

                #文件大小为0的文件处理
                filesize=$(stat -c%s $TD/${filename})
		#echo $filesize
                if [ ${filesize} -eq 0  ]; then

                       echo "Find error file : $TD/${filename}"

                       mv $TD/${filename} ./zeroavro
                fi

	done
	else
		continue
	fi
done
sleep 10
done
