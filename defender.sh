#!/bin/bash
# Program:
#       This program Will Detect The Potential DNS Attack's IP And Automatically Block Those IPs.
# History:
# 2016/04/11	InfiniteWing	First release

echo -e "This Shell Script Will Detect The Potential DNS Attack's IP And Automatically Block Those IPs."

tcpdump_tmplog=tcpdump_tmplog.log

tasktime=0
while :
do
	start_sec=`date "+%s"`

	/usr/sbin/tcpdump -i eth0 -tnn dst port 53 -c 10000| awk -F"." '{print $1"."$2"."$3"."$4}' | sort | uniq -c | sort -nr |head -20 > ${tcpdump_tmplog}

	end_sec=`date "+%s"`
	let dif_sec=end_sec-start_sec
	let tasktime=tasktime+dif_sec
	if [ ${tasktime} -ge "3600" ]; then
		echo -e "Time To Refresh iptables..."
		/sbin/iptables -F InfiniteWing
		tasktime=0
	fi

	echo -e "Total Use ${dif_sec}Seconds. Now Analyzing The Logs..."
	
	exec < ${tcpdump_tmplog}
	while read line
	do
		counter=$(echo $line | awk  '{print $1}')
		tcptype=$(echo $line | awk  '{print $2}')
		ipaddrs=$(echo $line | awk  '{print $3}')
		let query_per_sec=counter/dif_sec
		if [ ${query_per_sec} -ge "12" ] && [ ${tcptype} == "IP" ]; then
			echo "IP : ${ipaddrs} seems to be attackers.(Totally request ${counter} times, ${query_per_sec}/sec)"

			if /sbin/iptables -L -n | grep  -- ${ipaddrs}; then
				echo "Seems This IP had already been blocked."
			else
				/sbin/iptables -A InfiniteWing -p UDP --dport 53 -s ${ipaddrs} -j DROP
				/sbin/iptables -A InfiniteWing -p TCP --dport 53 -s ${ipaddrs} -j DROP
				echo "Block this IP Successfully."
			fi
		fi
	done
done

exit 0
