#!/bin/bash

clear
export GREP_COLORS="01;35"

RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
CYAN='\033[35m'
RESET='\033[0m'
BOLD='\033[1m'
BOLD_PINK='\033[1;35m'
DIV="=============================="

OPTIONS=("MOUNT_POINT" "TIME_ZONE")
SWITCHES=("-m", "-h")
OPTION_IDX=0
NEXT_ARG_VARIABLE=""

banner() {
	echo
	echo -e "\e[31m██╗     ██╗██╗   ██╗███████╗    ██████╗ ███████╗██╗██████╗ \e[0m"
	echo -e "\e[33m██║     ██║██║   ██║██╔════╝    ██╔══██╗██╔════╝██║██╔══██╗\e[0m"
	echo -e "\e[32m██║     ██║██║   ██║█████╗      ██║  ██║█████╗  ██║██████╔╝\e[0m"
	echo -e "\e[34m██║     ██║██║   ██║██╔══╝      ██║  ██║██╔══╝  ██║██╔══██╗\e[0m"
	echo -e "\e[35m███████╗██║╚██████╔╝███████╗    ██████╔╝██║     ██║██║  ██║\e[0m"
	echo -e "\e[36m╚══════╝╚═╝ ╚═════╝ ╚══════╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝\e[0m"
	echo
	echo -e "${GREEN}Perform live analysis on active Linux systems.${RESET}"
	echo
}

help() {
	clear
        banner
        echo "Usage: sudo $0"
        exit
}

log_header() {
	local heading=$1
	local sub_heading=$2

	if [ -z "$sub_heading" ]; then
		echo -e "${BLUE}${DIV}|${BOLD}${GREEN} ${heading} ${RESET}${BLUE}|${DIV}${RESET}"
	else
		echo -e "${BLUE}${DIV}|${BOLD}${GREEN} ${heading} - ${sub_heading} ${RESET}${BLUE}|${DIV}${RESET}"
	fi
}

log_value() {
	local title=$1
	local val=$2

	echo -e "${RED}${BOLD}[+] ${BLUE}${title}: ${RESET}${val}"
}

get_property() {
	local key=$1
	local file=$2
	
	echo $(cat $file | grep $key | cut -d '"' -f 2)
}

get_birth() {
	local path=$1

	stat "$home" | grep "Birth" | cut -d " " -f 3,4 | cut -d "." -f 1
}

initial_checks() {
	# Change timezone based on user input and target
	timezone="$(get_timezone)"

	if [ ! "$TIME_ZONE" ]; then
		export TZ="$timezone"
	else 
		export TZ="$TIME_ZONE"
	fi
}

init_check() {
       local init=$(ls -la /sbin/init  | cut -d "." -f 3 | cut -d "/" -f 3)
       
       echo init 
}

convert_timestamp() {
	local timestamp="$1"
	# Convert timestamp to the target timezone
	# Assumes the format of timestamp is YYYY-MM-DD HH:MM:SS for conversion
	date -d "$timestamp $from_tz" +"%Y-%m-%d %H:%M:%S" -u | TZ="$to_tz" date +"%Y-%m-%d %H:%M:%S"
}

to_lower() {
	echo "$1" | tr '[:upper:]' '[:lower:]'
}

to_upper() {
	echo "$1" | tr '[:lower:]' '[:upper:]'
}

determine_image_type() {
	# check mmls output for partition table
	local mmls_output=$(mmls "$1" 2>/dev/null)
	
	# if there is output, then it is a disk image
	if [ ! -z "$mmls_output" ]; then
		echo "disk"
	else
		# check if the output of the file command contains "filesystem"
		local file_output=$(file "$1")
		if [[ $file_output == *"filesystem"* ]]; then
			echo "filesystem"
		else
			echo "unknown"
		fi
	fi
}

# -----------------------------------------------------------
# DEVICE SETTINGS
# -----------------------------------------------------------
get_device_settings() {
	echo $(log_header "DEVICE SETTINGS")
	echo

	# OS Version
	if [ -f "/etc/os-release" ]; then
		os_version=$(get_property "PRETTY_NAME" /etc/os-release)
	elif [ -f "/etc/lsb-release" ]; then
		os_version=$(get_property "PRETTY_NAME" /etc/lsb-release)
	elif [ -f "/etc/redhat-release" ]; then
		os_version=$(get_property "PRETTY_NAME" /etc/redhat-release)
	elif [ -f "/etc/debian_version" ]; then
		os_version=$(get_property "PRETTY_NAME" /etc/debian_version)
	else
		os_version="Not Found"
	fi

	echo $(log_value "OS Version" "$os_version")

	# Kernel Version
	kernel_ver=$(ls /lib/modules)
	echo $(log_value "Kernel Version" "$kernel_ver")

	# Processor Architecture
	proc_arch="$(ls /lib/modules | cut -d "." -f 5)"

	if [ ! $proc_arch ]; then
		proc_arch="$(ls /lib/modules | cut -d "-" -f 3)"
	fi

	echo $(log_value "Processor Architecture" "$proc_arch")

	# Time Zone
	echo $(log_value "Time Zone" "$timezone")

	# Last Shutdown
	shutdown=$(last -x -f /var/log/wtmp | egrep "shutdown|reboot" | head -n 1 | sed 's/  / /g' | cut -d " " -f 1,6-10)
	shutdown_time=$(echo $shutdown | cut -d " " -f 2-5)
	shutdown_type=$(echo $shutdown | cut -d " " -f 1)
	echo $(log_value "Last Shutdown" "$shutdown_time ($shutdown_type)")

	# Hostname
	hostname=$(cat /etc/hostname)
	echo $(log_value "Hostname" "$hostname")
	
	# Init system
	init=$(ls -la /sbin/init  | cut -d "." -f 3 | cut -d "/" -f 3)
	echo $(log_value "Init System" "$init")

	echo
}

# -----------------------------------------------------------
# USERS
# -----------------------------------------------------------
get_users() {
	echo $(log_header "USERS")
	echo

	users=$(egrep "bash|zsh" /etc/passwd | cut -d ":" -f 1,3)

	for userid in $users; do
		id=$(echo "${userid}" | cut -d ":" -f 2)
		user=$(echo "${userid}" | cut -d ":" -f 1)

		home="$(grep "^$user" /etc/passwd | cut -d ":" -f 6)"

		disabled="$(cat /etc/shadow | cut -d ":" -f 1-3 | egrep "^$user(:\$|::)")"
		dis_enabled="$([ "$disabled" ] && echo -e "${BOLD_PINK}True${RESET}" || echo "False")"

		password="$(egrep "^$user:[^!][^:]*:.*$" /etc/shadow)"
		pass_enabled="$([ "$password" ] && echo -e "${BOLD_PINK}True${RESET}" || echo "False")"

		groups=$(cat /etc/group | grep $user | cut -d ":" -f 1 | sed ':a;N;$!ba;s/\n/, /g')
		creation="$(get_birth $home)"

		echo -e "$(log_value "$user ($id)" "")"
		echo -e "  ${BOLD}Creation: ${RESET}$creation"
		echo -e "  ${BOLD}Password: ${RESET}$pass_enabled"
		echo -e "  ${BOLD}Disabled: ${RESET}${dis_enabled}"
		echo -e "  ${BOLD}Groups: ${RESET}$(echo $groups | egrep --color=always "sudo|admin|wheel")"
		echo -e "  ${BOLD}Home: ${RESET}$home"
		echo
	done
}

# -----------------------------------------------------------
# BACKUP DIFF
# -----------------------------------------------------------

get_backup_diff() {
	echo $(log_header "BACKUP DIFF")
	echo

	for name in "shadow" "passwd" "group"; do
		local file="/etc/$name"

		if [ -f "$file-" ]; then
			echo -e "$(log_value "$name" "")"
			echo "Modified: $(stat $file | grep Modify | cut -d " " -f 2-3 | cut -d "." -f 1)"
			echo
			echo "$(diff $file- $file | egrep "<|>|-" | egrep --color=always ">*|$")"
			echo
		elif [ -f "$file~" ]; then
			echo -e "$(log_value "$name" "")"
			echo "Modified: $(stat $file | grep Modify | cut -d " " -f 2-3 | cut -d "." -f 1)"
			echo
			echo "$(diff $file~ $file | egrep "<|>|-" | egrep --color=always ">*|$")"
			echo
		else
			echo -e "$(log_value "$name" "")"
			echo "No $name file backup found..."
			echo
		fi
	done
}

# -----------------------------------------------------------
# INSTALLED SOFTWARE
# -----------------------------------------------------------
get_installed_software() {
	echo $(log_header "INSTALLED SOFTWARE")
	echo

	local dpkg="/var/log/dpkg.log"
	local yum="/var/log/yum.log"

	local software="wget|curl|php|sql|apache|drupal|ssh|nginx"

	if [ -f "$dpkg" ]; then
		echo "$(cat "$dpkg" | grep " installed " | egrep --color=always "$software|$" )"
	elif [ -f "$yum" ]; then
		echo "$(grep -i installed $yum | sed -e "s/Installed: //" | egrep --color=always "$software|$")"
	else
		echo "$(log_value "Could't find Installed Software..." "")"
	fi

	echo
}

# -----------------------------------------------------------
# CRON JOBS
# -----------------------------------------------------------
get_cron_jobs() {
	echo $(log_header "CRON JOBS")
	echo

	local patterns="wget |curl |nc |bash |sh |base64|exec |/tmp/|perl|python|ruby|nmap |tftp|php"

	local cron_files=(
			"/etc/crontab"
			"/etc/cron.d"
			"/etc/cron.hourly"
			"/etc/cron.daily"
			"/etc/cron.weekly"
			"/etc/cron.monthly"
	)

	local user_cron_directories=(
			"/var/spool/cron/crontabs" # Debian/Ubuntu
			"/var/spool/cron"          # Red Hat/CentOS
	)

	print_crons() {
		local file=$1
		local result="$(cat "$file" | grep -v "#" | egrep --color=always "$patterns")"
		
		if [ ! -z "$result" ]; then
			echo -e $(log_value "$file" "")
			echo "$result"
			echo
		fi
	}

	scan_crons() {
		local path="$1"

		if [ -f "$path" ]; then
			print_crons "$path"
		elif [ -d "$path" ]; then
			for file in "$path"/*; do
				if [ -f "$file" ]; then
					print_crons "$file"
				fi
			done
		fi
	}

	for file in "${cron_files[@]}"; do
		if [ -e "$file" ]; then
			scan_crons "$file"
		fi
	done

	for dir in "${user_cron_directories[@]}"; do
		if [ -d "$dir" ]; then
			for user_cron in "$dir"/*; do
				if [ -f "$user_cron" ]; then
					scan_crons "$user_cron"
				fi
			done
		fi
	done
}

# -----------------------------------------------------------
# NETWORK
# -----------------------------------------------------------
get_network() {
	echo $(log_header "NETWORK")
	echo

	echo $(log_value "Hosts" "")
	hosts=$(cat /etc/hosts | egrep -v "^#")
	echo "$hosts"
	echo

	echo $(log_value "DNS" "")

	if [ -f "/etc/resolv.conf" ]; then
		dns=$(cat /etc/resolv.conf | egrep -v "^#")
		echo "$dns"
	else
		echo "/etc/resolv.conf file does not exist..."
	fi

	echo

	echo $(log_value "Interfaces" "")

	get_key() {
		local key=$1
		local file=$2

		echo "$(grep $key $file | tr -d '"' | cut -d "=" -f 2)"
	}

	debian="/etc/network/interfaces"
	rhel="/etc/sysconfig/network-scripts/ifcfg-*"

	if [ -f $debian ]; then
		interfaces="$(cat $debian | grep "iface")"

		while IFS= read -r line; do
			int="$(echo $line | cut -d " " -f 2)"
			type="$(echo $line | cut -d " " -f 4)"

			echo -e "${BOLD_PINK}$int:${RESET}"

			if [ "$type" == "dhcp" ]; then
				lease_config="$(cat /var/lib/dhcp/dhclient.$int.leases)"

				ip_address="$(echo "$lease_config" | grep -oP "fixed-address \K\d{1,3}(\.\d{1,3}){3}" | tail -n 1)"
				subnet_mask="$(echo "$lease_config" | grep -oP "subnet-mask \K\d{1,3}(\.\d{1,3}){3}" | tail -n 1)"
				default_gateway="$(echo "$lease_config" | grep -oP "routers \K\d{1,3}(\.\d{1,3}){3}" | tail -n 1)"
				renew_time="$(echo "$lease_config" | grep -oP 'renew \d+ \K\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}' | tail -n 1)"
				
				echo -e "  ${BOLD}Type:${RESET} $type"
				echo -e "  ${BOLD}IP:${RESET} $ip_address"
				echo -e "  ${BOLD}Mask:${RESET} $subnet_mask"
				echo -e "  ${BOLD}Gateway:${RESET} $default_gateway"
				echo -e "  ${BOLD}Set Time:${RESET} $renew_time"
			else
				echo -e "  ${BOLD}Type:${RESET} $type"
			fi

			echo
		done <<< "$interfaces"
	elif [ ! -z "$(cat $rhel)" ]; then
		for config in $(ls $rhel); do
			local uuid="$(get_key "UUID" "$config")"
			local int="$(get_key "DEVICE" "$config")"
			local type="$(get_key "BOOTPROTO" "$config")"

			echo -e "${BOLD_PINK}$int:${RESET}"

			if [ "$type" == "dhcp" ]; then
				lease_config="$(cat /var/lib/NetworkManager/dhclient-$uuid*)"

				ip_address="$(echo "$lease_config" | grep -oP "fixed-address \K\d{1,3}(\.\d{1,3}){3}" | tail -n 1)"
				subnet_mask="$(echo "$lease_config" | grep -oP "subnet-mask \K\d{1,3}(\.\d{1,3}){3}" | tail -n 1)"
				default_gateway="$(echo "$lease_config" | grep -oP "routers \K\d{1,3}(\.\d{1,3}){3}" | tail -n 1)"
				renew_time="$(echo "$lease_config" | grep -oP 'renew \d+ \K\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}' | tail -n 1)"
				
				echo -e "  ${BOLD}Type:${RESET} $type"
				echo -e "  ${BOLD}IP:${RESET} $ip_address"
				echo -e "  ${BOLD}Mask:${RESET} $subnet_mask"
				echo -e "  ${BOLD}Gateway:${RESET} $default_gateway"
				echo -e "  ${BOLD}Set Time:${RESET} $renew_time"
			else
				echo -e "  ${BOLD}Type:${RESET} static"
				echo -e "  ${BOLD}IP:${RESET} $(get_key "IPADDR" "$config")"
				echo -e "  ${BOLD}Mask:${RESET} $(get_key "NETMASK" "$config")"
			fi
			
			echo
		done
	else
		echo "Cannot find network configurations..."
		echo
	fi

	# NetworkManager Connections - only lists a single interface, need to fix this
	netman="/etc/NetworkManager/system-connections/*"
	
	if [ -f $netman ]; then
		for config in $netman; do
			local id=$(cat $netman | grep "^id=" | cut -d "=" -f 2)
			local type=$(cat $netman | grep "^type=" | cut -d "=" -f 2)
			local ip=$(cat $netman | grep "^address" | cut -d "=" -f 2 | cut -d "," -f 1)
			local mac=$(cat $netman | grep "^mac-address=" | cut -d "=" -f 2)
			local dns=$(cat $netman | grep "^dns=" | cut -d "=" -f 2 | sed 's/;//g')
			local gateway=$(cat $netman | grep "^address" | cut -d "=" -f 2 | cut -d "," -f 2 )

			echo -e "${BOLD_PINK}$id:${RESET}"
			echo -e "  ${BOLD}Type:${RESET} $type"
			echo -e "  ${BOLD}IP:${RESET} $ip"
			echo -e "  ${BOLD}MAC:${RESET} $mac"
			echo -e "  ${BOLD}DNS:${RESET} $dns"
			echo -e "  ${BOLD}Gateway:${RESET} $gateway"
		done
	fi
}

# -----------------------------------------------------------
# LAST MODIFIED
# -----------------------------------------------------------
get_last_modified() {
	echo $(log_header "LAST MODIFIED")
	echo

	last_modified="$(find  -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' 2>/dev/null | sort | tail -n 20)"
	echo "$last_modified"

	echo
}

# -----------------------------------------------------------
# SESSIONS
# -----------------------------------------------------------
get_remote_sessions() {
	
	echo $(log_header "REMOTE SESSIONS")
	echo

	if [ -e /var/log/auth.log ]; then
		output="$(egrep "session opened|session closed" /var/log/auth.log)"
	elif [ -e /var/log/secure ]; then
		output="$(egrep "session opened|session closed" /var/log/secure)"
	else
		output="Cannot find remote session information..."
	fi

	echo "$output"
	echo
}

# -----------------------------------------------------------
# LAST LOGINS
# -----------------------------------------------------------
get_last_logins() {
	echo $(log_header "LAST LOGINS")
	echo

	local output="$(lastlog -R  | egrep -v "\*\*Never")"

	if [ "/var/log/lastlog" ]; then
		if [ "$output" ]; then
			while IFS= read -r line; do
				if [ "$(echo $line | egrep -v "Username|Port|From|Latest")" ]; then
					is_ip="$(echo $line | grep -oP '\b\d{1,3}(\.\d{1,3}){3}\b')"

					local user="$(echo $line | cut -d " " -f 1)"
					local type="$(echo $line | cut -d " " -f 2)"

						echo -e "${BOLD_PINK}$user${RESET}:"
						echo -e "  ${BOLD}Type: ${RESET}$type"
					if [ "$is_ip" ]; then
						local from="$(echo $line | cut -d " " -f 3)"
						local date_time="$(echo $line | cut -d " " -f 4-10)"

						echo -e "  ${BOLD}From: ${RESET}$from (Remote)"
						echo -e "  ${BOLD}Date/Time: ${RESET}$date_time"
						echo
					else
						local date_time="$(echo $line | cut -d " " -f 3-10)"

						echo -e "  ${BOLD}From: ${RESET}Local"
						echo -e "  ${BOLD}Date/Time: ${RESET}$date_time"
						echo
					fi
				fi
			done <<< "$output"
		else
			echo "/var/log/lastlog is empty..."
			echo
		fi
	else
		echo "/var/log/lastlog does not exist..."
		echo
	fi
}

# -----------------------------------------------------------
# WEB LOGS
# -----------------------------------------------------------
get_web_logs() {
	echo $(log_header "WEB LOGS")
	echo

	local log_file="/var/log/apache2/access.log"

	if [ -f "$log_file" ]; then
		echo -e "$(log_value "IP Addresses" "")"
		awk '{print $1}' "$log_file" | sort | uniq -c | sort -nr | head -n 10
		echo

		echo -e "$(log_value "User Agents" "")"
		local anomalous_useragents="wpscan"
		awk -F '"' '{print $6}' "$log_file" | sort | uniq -c | sort -nr | head -n 10 | egrep --color=always -i "$anomalous_useragents|$"
		echo

		query="$(cat $log_file | cut -d " " -f 1,4-7 | grep "POST" | grep "plugins" | head -n 10 )"
		if [ ! -z "$query" ]; then
			echo -e "$(log_value "Plugins" "")"
			echo "$query"
		fi
		echo

		query="$(cat $log_file | cut -d " " -f 1,4-7 | grep "POST" | grep "theme" | head -n 10 )"
		if [ ! -z "$query" ]; then
			echo -e "$(log_value "Themes" "")"
			echo "$query"
		fi
		echo

		query="$(cat $log_file | cut -d " " -f 1,4-7 | egrep --color=always "c99.php|shell.php|shell=|exec=|cmd=|act=|whoami|pwd|base64|eval" | head -n 10 )"
		if [ ! -z "$query" ]; then
			echo -e "$(log_value "Potential Shells" "")"
			echo "$query"
		fi
		echo

		query="$(cat $log_file | cut -d " " -f 1,4-7 | egrep --color=always "\.(exe|sh|bin|zip|tar|gz|rar|pl|py|rb|log|bak)$" | head -n 10 )"
		if [ ! -z "$query" ]; then
			echo -e "$(log_value "Anomalous Extensions" "")"
			echo "$query"
		fi
		echo

		query="$(cat $log_file | cut -d " " -f 1,4-7 | egrep "wp-content/uploads" | tail -n 10 )"
		if [ ! -z "$query"]; then
			echo -e "$(log_value "Uploaded Content" "")"
			echo "$query"
		fi
	else
		echo "Apache logs do not exist..."
		echo
	fi
}

# -----------------------------------------------------------
# COMMAND HISTORY
# -----------------------------------------------------------
get_command_history() {
	echo $(log_header "COMMAND HISTORY")
	echo

	local users=$(egrep "(bash|zsh)" /etc/passwd | tr -d ' ')
	local keywords="/tmp|/etc|whoami|id|passwd"

	for line in $users; do
		local user=$(echo "${line}" | cut -d ":" -f 1)
		local shell=$(echo "${line}" | cut -d ":" -f 7 | egrep "(bash|zsh)")
		local home="$(grep "^$user" /etc/passwd | cut -d ":" -f 6)"

		history="$(cat $home/.*history | egrep --color=always "$keywords|$")"

		echo -e "$(log_value "$user ($shell)" "")"
		echo "$history"
		echo
	done
}

# -----------------------------------------------------------
# USER FILES
# -----------------------------------------------------------
get_user_files() {
	echo $(log_header "USER FILES")
	echo

	local users=$(egrep "(bash|zsh)" /etc/passwd | tr -d ' ')

	for line in $users; do
		local user=$(echo "${line}" | cut -d ":" -f 1)
		local home="$(grep "^$user" /etc/passwd | cut -d ":" -f 6)"

		local files="$(ls -l $home/*)"

		echo -e "$(log_value "$user ($home)" "")"
		echo "$files"
		echo
	done

	echo
}

# -----------------------------------------------------------
# TEMPORARY FILES
# -----------------------------------------------------------
get_temp_files() {
	echo $(log_header "TMP FILES")
	echo

	echo "$(ls -lh /tmp)"

	echo
}

# -----------------------------------------------------------
# APACHE CONFIG
# -----------------------------------------------------------
get_apache_config() {
	echo $(log_header "APACHE CONFIG")
	echo

	local dir="/etc/apache2/sites-enabled"

	if [ -d "$dir" ]; then
		for file in "$dir"/*; do
			if [ -f "$file" ]; then
				local filename="$(basename "$file")"

				echo -e "$(log_value "$filename" "")"
				echo "$(cat $file | grep -v "#")"
				echo
			fi
		done
	else
		echo "Apache is not installed..."
		echo
	fi
}


get_timezone() {
	if [ -f "/etc/timezone" ]; then
		echo "$(cat /etc/timezone)"
	else
		echo "$(realpath /etc/localtime | sed 's/.*zoneinfo\///')"
	fi
}

execute_all() {
      banner
      
      initial_checks
      get_device_settings
      get_users
      get_command_history
      get_user_files
      get_temp_files
      get_backup_diff
      get_installed_software
      get_cron_jobs
      get_network
      get_remote_sessions
      get_last_logins
      get_apache_config
      get_web_logs
}

execute_all
