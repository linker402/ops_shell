#!/usr/bin/expect  -f
set host [lindex $argv 0]
set esdir [lindex $argv 1]
spawn ssh $host
expect "*]#"
send "$esdir/elasticsearch/elasticsearch/bin/service/elasticsearch start\r"
expect "*]#"
send "logout\r"
