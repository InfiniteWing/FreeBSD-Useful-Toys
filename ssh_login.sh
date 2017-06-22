#!/bin/bash
# Author: InfiniteWing
# Date:   2017-06-22
# This shell script will detect the login event on ssh
# and then automatically send an warning email via ssmtp

# I use ssmtp with gmail on FreeBSD 11.0
# You can use your own mail service if you want

# replace these path to your own
log_file="/var/log/auth.log"
mail_log_path="/var/log/ssmtp/"
current_login_count_file="/usr/local/etc/ssmtp/current_login_count"

mail_to="your mail here"
mail_from="your mail here"
mail_subject="subject here"
while :
do
	typeset -i current_login_count=$(cat $current_login_count_file)
	login_count=0
	while read line; do
		# replace your own regex here
		regex="(.)*Accepted keyboard-interactive(.)*for(.)*from(.)*port(.)*ssh2(.)*"
		if [[ $line =~ $regex ]]; then
			login_count=$(($login_count+1))
			if [[ login_count -gt current_login_count ]]; then
				random_id=$(( $RANDOM % 9000 + 1000 ))
				current_date_time="`date +%Y%m%d%H%M%S`"
				current_date_time_str="`date +'%Y-%m-%d %H:%M:%S'`"
				mail_file_id="$current_date_time-$random_id.mail"
				mail_file="$mail_log_path$mail_file_id"
				ip="$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<< "$line")"
				echo "To: $mail_to" >> $mail_file
				echo "From: $mail_from" >> $mail_file
				mail_subject="$mail_subject $current_date_time_str user($ip) login"
				echo "Subject: $mail_subject" >> $mail_file
				echo "" >> $mail_file
				echo "At $current_date_time_str, an user($ip) login." >> $mail_file
				echo "$line" >> $mail_file
				command="ssmtp -v $mail_to < $mail_file"
				eval $command
				current_login_count=$login_count
			fi
		fi
	done < $log_file
	echo $current_login_count>$current_login_count_file
	sleep 30
done
