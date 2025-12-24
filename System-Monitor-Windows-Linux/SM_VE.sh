#!/bin/bash
export DIALOGRC="./mytheme.rc"
#=====================
#Other Functionss
#=====================
log_data()
{
	log_file="/app/system_monitor_log.log"
	echo "System Monitor Entry $(date)" >> "$log_file" 
	while true; do
		sudo_confirm
		timestamp=$(date +"%Y-%m-%d %H-%M-%S")
		get_cpu_info
        get_gpu_info
		get_disk_info
		get_memory_info
		get_network_info
		get_system_load_info
		get_rom_info
		echo "[$timestamp]^CPU_Model:${cpu_model}#CPU_Usage:${cpu_usage}^" \
        "GPU_Model:${gpu_model}#GPU_Usage:${gpu_usage}#GPU_Temp:${gpu_temp_display}^" \
		"DISK_INFO:${disk_info_aggregated}^" \
		"MEM_Total:${memTotal}#MEM_Used:${memUsed}#MEM_Avail:${memAvail}^" \
		"NET_Details:${network_details}^" \
		"LOAD_Users:${num_of_users}#LOAD_Tasks:${tasks}#LOAD_Uptime:${uptime_hours}:${uptime_mins}:${uptime_secs}^" \
		"ROM_Kernel:${kernel}" >> "$log_file"
		sleep 60
	done
}

sudo_confirm()
{
	sudo -n true 2>/dev/null
	doesUserNeedPassword=$?
	if [ $doesUserNeedPassword -ne 0 ]; then
		clear
	    	while true; do
			user_password=$(dialog --title "Password" --passwordbox "Enter the device's password." 8 70 "" --stdout 2> >(grep -v -e "Expected a box option" -e "Use --help to list options." >&2))
			exit_code=$?
			case $exit_code in
				255|0)
		    		user_password=$(echo -n "$user_password")
		    		if [ -z "$user_password" ]; then
		    			tput bel
		            		dialog --title "Input Error" --msgbox "\nPassword field cannot be empty. Please enter your password." 9 70
		            		continue
		        	fi
		        	sudo -S true <<< "$user_password" 2> >(grep -v "^\[sudo\] password for" >&2)
		        	isPasswordCorrect=$?
		        	if [ $isPasswordCorrect -eq 0 ]; then
		        		dialog --title "Success" --msgbox "\nPassword is correct, proceed." 9 70
		        		break
		        	else
		        		clear
		            		dialog --title "Password Incorrect" --msgbox "\nEntered password is incorrect, please try again." 9 70
		        	fi
		        	;;
		        	1)
		    		dialog --title "Process Aborted" --msgbox "\nProcess aborted by user." 9 70
		        	clear
		        	exit 1
		        	;;
		    	*)
		        	dialog --title "Error" --msgbox "\nUnexpected error, please try again." 9 70
		        	;;
			esac
	    	done
	fi
}

safe_kill_logger()
{
	if kill -0 "$logger_pid" 2>/dev/null; then
        	kill "$logger_pid" 2>/dev/null
    	fi
}

cleanup()
{
	safe_kill_logger
	stty sane
    	clear
    	exit
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#================
#Helper Functions
#================
get_cpu_info()
{
	cpu_model=$(lscpu | grep "Model name" | awk -F ':' '{print $2}' | xargs)
	cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
	cpu_temp_display=$(sudo sensors | grep "Package id 0:" | awk -F '[: ]' '{print $6}')
	cpu_temp_val=$(sudo sensors | grep "Package id 0:" | awk -F '[: ]' '{print $6}' | tr -d "+°C")
}

get_gpu_info()
{
	gpu_model=$(nvidia-smi -q | grep "Product Name" | awk -F ':' '{print $2}' | xargs)	
	igpu_model=$(lspci | grep -i vga | awk -F ':' '{print $4}' | xargs)
    	igpu_usage=$(sudo intel_gpu_top -J -s 1 2>/dev/null | grep '"busy":' | head -n 1 | sed -e 's/"busy"//g' -e 's/: //g' -e 's/,//g' | xargs)
    	gpu_usage=$(nvidia-smi -q | sed -n '/Utilization/,/Encoder Stats/p' | sed -e 's/Encoder Stats//g' -e 's/Utilization//g' | xargs)
    	gpu_temp_display=$(nvidia-smi -q | grep "GPU Current Temp" | awk -F ':' '{print $2}' | xargs)
    	gpu_temp=$(nvidia-smi -q | grep "GPU Current Temp" | awk -F ':' '{print $2}' | xargs | tr -d "°C")
}

get_disk_info()
{
	disk_list=$(lsblk -ndo NAME,TYPE | grep 'disk$' | cut -d' ' -f1)
	disk_info_aggregated=""
    	for disk in $disk_list; do
        	d_model=$(lsblk -ndo MODEL "/dev/$disk")
		d_vendor=$(lsblk -ndo VENDOR "/dev/$disk" | xargs)
		d_size=$(lsblk -ndo SIZE "/dev/$disk" | xargs)
		d_used=$(lsblk -o FSUSED -n "/dev/$disk" | xargs)
		d_free=$(lsblk -o FSAVAIL -n "/dev/$disk" | xargs)
		disk_info_aggregated+="${disk}#Model:${d_model}#Vendor:${d_vendor}#Size:${d_size}#Used:${d_used}#Free:${d_free}#Health:${d_smart}|"
    	done
    	disk_info_aggregated=${disk_info_aggregated%?}
}

get_memory_info()
{
	memTotal=$(free -m | grep 'Mem: ' | awk '{print $2}')
	memUsed=$(free -m | grep 'Mem: ' | awk '{print $3}')
	memAvail=$(free -m | grep 'Mem: ' | awk '{print $7}')
}

get_network_info()
{
    network_details=""
    for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
        network_device_type=$(ip -o link show $iface 2>/dev/null | grep -oP 'link/\K\w+' | xargs)
        network_device_status=$(ip link show $iface 2>/dev/null | grep -oP 'state \K[^ ]+')
        n_mac=$(ip addr show $iface 2>/dev/null | awk '/link\/ether/ {print $2}')
        n_ip4=$(ip addr show $iface 2>/dev/null | awk '/inet / {print $2}' | grep -v '::' | tr '\n' ' ' | xargs) 
        n_ip6=$(ip addr show $iface 2>/dev/null | awk '/inet6 / {print $2}' | tr '\n' ' ' | xargs) 
        network_details+="NIN:${iface}#TYPE:${network_device_type}#STATUS:${network_device_status}#MAC:${n_mac}#IP4:${n_ip4}#IP6:${n_ip6}|"
    done
    network_details=${network_details%?}
}

get_system_load_info()
{
	num_of_users=$(who | wc -l)
	time_secs=$(cat /proc/uptime | awk '{print int($1)}')
	uptime_hours=$(($time_secs/3600))
	uptime_mins=$(($time_secs%3600/60))
	uptime_secs=$(($time_secs%60))
	tasks=$(top -bn1 | grep 'Tasks' | awk '{print $2}')
}

get_rom_info()
{
	rom_vendor_version=$(sudo dmidecode -t bios 2>/dev/null | grep -E 'Vendor|Version' | awk -F ':' '{print $1, $2}' | xargs)
	rom_revision=$(sudo dmidecode -t bios 2>/dev/null | grep -E 'BIOS Revision|Firmware Revision' | awk -F ':' '{print $1, $2}' | xargs)
	rom_size=$(sudo dmidecode -t bios 2>/dev/null | grep -E 'Release Date|ROM Size' | awk -F ':' '{print $2}' | tr -d ' ' | sed -n '2p')
	rom_date=$(sudo dmidecode -t bios 2>/dev/null | grep -E 'Release Date|ROM Size' | awk -F ':' '{print $2}' | tr -d ' ' | sed -n '1p')
	kernel=$(uname -r)
}
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#=================
#Display Functions
#=================
display_cpu_info()
{
	while true
	do
		clear
		get_cpu_info
		warnining=""
		if (( $(echo "$cpu_temp_val >= 80" | bc -l) )); then
			warnining="WARNING: Heat Level at Critical Levels, Please turn off any process to reduce the heat"
		elif (( $(echo "$cpu_temp_val >= 60" | bc -l) )); then
			warnining="WARNING: Heat Level at High Levels"
		elif (( $(echo "$cpu_temp_val >= 40" | bc -l) )); then
			warnining="WARNING: Heat Level Starting to Rise"
		fi
		content="\nCPU Model: $cpu_model\n\nCPU Usage: $cpu_usage\n\nPress 'b' to go back"
		dialog --title "CPU INFORMATION" --infobox "$content" 9 70
		read -t 0.01 -n 10000 discard
		read -n 1 -s -t 3 exit
		if [[ $exit == "b" ]]; then
			break
		fi
	done
}

display_gpu_info()
{
	while true
	do
		clear
		get_gpu_info
		warnining=""
		if (( $(echo "$gpu_temp >= 80" | bc -l) )); then
			warnining="WARNING: Heat Level at Critical Levels, Please turn off any process to reduce the heat"
		elif (( $(echo "$gpu_temp >= 60" | bc -l) )); then
			warnining="WARNING: Heat Level at High Levels"
		elif (( $(echo "$gpu_temp >= 40" | bc -l) )); then
			warnining="WARNING: Heat Level Starting to Rise"
		fi
		content="\nGPU Model: $gpu_model\n\nGPU Usage: $gpu_usage\n\nGPU Temperature: $gpu_temp_display\n\n$warnining\n\nPress 'b' to go back"
		dialog --title "GPU INFORMATION MENU" --infobox "$content" 13 90
		read -t 0.01 -n 10000 discard
		read -n 1 -s -t 4 exit
		if [[ $exit == "b" ]]; then
			break
		fi
	done
}

display_disk_info()
{
	clear
	get_disk_info
	tmpfile="/tmp/system_monitor_disk.txt"
	latest_time=$(date +"%Y-%m-%d %H:%M:%S")
	final_info="\nLast Updated: $latest_time\n"
	final_info+="========================================\n"
	IFS='|' read -ra disks <<< "$disk_info_aggregated"
	for disk_info in "${disks[@]}"; do
		disk_name=$(echo "$disk_info" | awk -F'#Model:' '{print $1}')
		model=$(echo "$disk_info" | awk -F'#Model:' '{print $2}' | awk -F'#Vendor:' '{print $1}')
		vendor=$(echo "$disk_info" | awk -F'#Vendor:' '{print $2}' | awk -F'#Size:' '{print $1}')
		size=$(echo "$disk_info" | awk -F'#Size:' '{print $2}' | awk -F'#Used:' '{print $1}')
		used=$(echo "$disk_info" | awk -F'#Used:' '{print $2}' | awk -F'#Free:' '{print $1}')
		free=$(echo "$disk_info" | awk -F'#Free:' '{print $2}' | awk -F'#Health:' '{print $1}')
			
		IFS=' ' read -ra used_arr <<< "$used"
		IFS=' ' read -ra free_arr <<< "$free"
		
		used_info=""
		free_info=""
		for pn in "${!used_arr[@]}"; do
			used_info+="Partition $((pn+1)): ${used_arr[pn]}\n"
		done
		for pn in "${!free_arr[@]}"; do
			free_info+="Partition $((pn+1)): ${free_arr[pn]}\n"
		done
			
		final_info+="\nDisk: ${disk_name:-N/A}\n"
		final_info+="Model: ${model:-N/A}\n"
		final_info+="Vendor: ${vendor:-N/A}\n"
		final_info+="Size: ${size:-N/A}\n"
		final_info+="Used Space:\n${used_info:-N/A}\n"
		final_info+="Free Space:\n${free_info:-N/A}\n"
		final_info+="\n----------------------------------------\n"
	done
	echo -e "$final_info" > "$tmpfile"
	dialog --exit-label "Back" --title "DISK INFORMATION" --textbox "$tmpfile" 45 90
}

display_memory_info()
{
	while true
		do
		clear
		get_memory_info
		total_mem="\nTotal Memory Size: $memTotal MB\n"
		mem_used="Memory Used: $memUsed MB\n"
		mem_available="Memory Available: $memAvail MB\n"
		dialog --title "MAIN MEMORY INFORMATION" --infobox "$total_mem$mem_used$mem_available\nPress 'b' to go back to menu" 9 60
		echo
		read -t 0.01 -n 10000 discard
		read -n 1 -s -t 3 exit
		if [[ $exit == "b" ]]; then
			break
		fi
	done
}

display_network_info()
{
	clear
	get_network_info
	tmpfile="/tmp/system_monitor_network.txt"
	latest_time=$(date +"%Y-%m-%d %H:%M:%S")
	final_info="\nLast Updated: $latest_time\n"
	final_info+="========================================\n"
	IFS='|' read -ra interfaces <<< "$network_details"
	for iface_data in "${interfaces[@]}"; do
		iface="${iface_data#NIN:}"
		iface="${iface%%#TYPE:*}"
		type=$(echo "$iface_data" | grep -oP '#TYPE:\K[^#]*')
		status=$(echo "$iface_data" | grep -oP '#STATUS:\K[^#]*')
		mac=$(echo "$iface_data" | grep -oP '#MAC:\K[^#]*')
		ip4=$(echo "$iface_data" | grep -oP '#IP4:\K[^#]*')
		ip6=$(echo "$iface_data" | grep -oP '#IP6:\K[^#]*')
		
		final_info+="\nNetwork Device: $iface\n"
		final_info+="Type: ${type:-N/A}\n"
		final_info+="Status: ${status:-N/A}\n"
		final_info+="Mac Address: ${mac:-N/A}\n"
		final_info+="IPv4: ${ip4:-N/A}\n"
		final_info+="IPv6: ${ip6:-N/A}\n"
		final_info+="\n----------------------------------------\n"
	done
	echo -e "$final_info" > "$tmpfile"
	dialog --exit-label "Back" --title "NETWORK INTERFACE PROPERTIES" --textbox "$tmpfile" 45 90
}

display_system_load_info()
{
	while true
	do
		clear
		get_system_load_info
		logged_sessions_num="\nNumber of Logged in Sessions: $num_of_users\n"
		sys_uptime="System Uptime: $uptime_hours:$uptime_mins:$uptime_secs\n"
		bg_process="Background Processes: $tasks\n"
		dialog --title "SYSTEM LOAD METRICS" --infobox "$logged_sessions_num$sys_uptime$bg_process\nPress 'b' to go back to menu" 9 60
		read -t 0.01 -n 10000 discard
		read -n 1 -s -t 5 exit
		if [[ $exit == "b" ]]
		then
			break
		fi
	done
}

display_rom_info()
{
	while true
	do
		clear
		get_rom_info
		kernel_version="Kernel version: $kernel\n"
		dialog --title "ROM INFORMATION" --infobox "\n$kernel_version\nPress 'b' to go back to menu" 7 80
		read -t 0.01 -n 10000 discard
		read -n 1 -s -t 60 exit
		if [[ $exit == "b" ]]
		then
			break
		fi
	done
}

exit_program()
{
	dialog --yesno "Are you sure you want to exit ?" 7 40
	isExit=$?
	if [[ $isExit -eq 0 ]]; then
		safe_kill_logger
		for exit_meter in "20" "40" "60" "80" "100"; do		
			echo $exit_meter | dialog --gauge "Goodbye:D\nExiting$exit_animation" 8 40
			sleep 0.7
		done
		clear
		exit 0
	fi		
}	
#==============
#Main menu loop
#===============
system_logo=$(cat << 'EOF'
 /$$      /$$                     /$$   /$$                         /$$                            /$$$$$$                        /$$                            
| $$$    /$$$                    |__/  | $$                        |__/                           /$$__  $$                      | $$                            
| $$$$  /$$$$  /$$$$$$  /$$$$$$$  /$$ /$$$$$$    /$$$$$$   /$$$$$$  /$$ /$$$$$$$   /$$$$$$       | $$  \__/ /$$   /$$  /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$/$$$$ 
| $$ $$/$$ $$ /$$__  $$| $$__  $$| $$|_  $$_/   /$$__  $$ /$$__  $$| $$| $$__  $$ /$$__  $$      |  $$$$$$ | $$  | $$ /$$_____/|_  $$_/   /$$__  $$| $$_  $$_  $$ 
| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  | $$    | $$  \ $$| $$  \__/| $$| $$  \ $$| $$  \ $$       \____  $$| $$  | $$|  $$$$$$   | $$    | $$$$$$$$| $$ \ $$ \ $$
| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ /$$| $$  | $$| $$      | $$| $$  | $$| $$  | $$       /$$  \ $$| $$  | $$ \____  $$  | $$ /$$| $$_____/| $$ | $$ | $$
| $$ \/  | $$|  $$$$$$/| $$  | $$| $$  |  $$$$/|  $$$$$$/| $$      | $$| $$  | $$|  $$$$$$$      |  $$$$$$/|  $$$$$$$ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$ | $$ | $$
|__/     |__/ \______/ |__/  |__/|__/   \___/   \______/ |__/      |__/|__/  |__/ \____  $$       \______/  \____  $$|_______/    \___/   \_______/|__/ |__/ |__/
                                                                                  /$$  \ $$                 /$$  | $$                                            
                                                                                 |  $$$$$$/                |  $$$$$$/                                            
                                                                                  \______/                  \______/
EOF
)

other_logos=$(cat << 'EOF'
                                .:xxxxxxxx:.				
                             .xxxxxxxxxxxxxxxx.			  +   @   +             +                  +   @          
                            :xxxxxxxxxxxxxxxxxxx:.	   |   >*v=-    .     +             *           o     +                .    
                           .xxxxxxxxxxxxxxxxxxxxxxx:	  -O-        +   @o               .           +   @        .          +       +   @o             +   @o             
                          :xxxxxxxxxxxxxxxxxxxxxxxxx:		   |                    _,.-----.,_       >*=-   |.     +  o    |          
                          xxxxxxxxxxxxxxxxxxxxxxxxxxX:		           +    *    .-'.         .'-.          -O-         +             +   @o             
                          xxx:::xxxxxxxx::::xxxxxxxxx:		      *            .'.-'   .---.   `'.'.         |    @o    +   @o             
                         .xx:   ::xxxxx:     :xxxxxxxx		 .                /_.-'   /     \   .'-.\                   +     o     >*=-    .     +        +   @o             
                         :xx  x.  xxxx:  xx.  xxxxxxxx		         ' -=*<  |-._.-  |   @   |   '-._|  >*=-    .     + 
                         :xx xxx  xxxx: xxxx  :xxxxxxx		 -- )--           \`-.    \     /    .-'/                 |  +   @o         o     >*=-    .     +     @o          
                         'xx 'xx  xxxx:. xx'  xxxxxxxx	 -- )--	       *     + \   `.'.    '---'   /.'.'    +       o    -O-   
                          xx ::::::xx:::::.   xxxxxxxx		                  .  '-._         _.-'  .                 | 
                          xx:::::.::::.:::::::xxxxxxxx	o      >*=-      |               `~~~~~~~`       - --===D             +         + @   +   @o             +   @o          
                          :x'::::'::::':::::':xxxxxxxxx.		   o    -O-      *>*=-    .     +   .                  *        +          
                          :xx.::::::::::::'   xxxxxxxxxx	        |                      +         .            +    				   o     >*=-    .     +  	
                          :xx: '::::::::'     :xxxxxxxxxx.	 jgs       +   @       .     @      o     >*=-    .     	+            o     >*=-    .       *       
                         .xx     '::::'        'xxxxxxxxxx.	       o      >*=-    .     +                    o               .           + *          o           .  
                       .xxxx                     'xxxxxxxxx.		*=-    .     +--===D@   			     _,.-----.,_  	@       @
                     .xxxx                         'xxxxxxxxx.		@    |  o     >*=- 	 . >*=-    .o     >*=-    .-'.         .'-.  >*=-  
                   .xxxxx:                          xxxxxxxxxx.		   +        --== =D                             .'.-'   .---.   `'.'.              .           + 				
                  .xxxxx:'                          xxxxxxxxxxx.		@      |       @ vo     >*=-    .o    ./_.-'   /     \   .'-.\ -.\         >*=-    .     +     + 
                 .xxxxxx:::.           .       ..:::_xxxxxxxxxxx:.	  @      o     >*           o     >*=         |-._.-  |   @   |   '-._|    +   .            .
                .xxxxxxx''      ':::''            ''::xxxxxxxxxxxx.           *>*=    --==    -Oo     >*=-    .o       \`-.    \     /    .-'/ '/    o     >*=-    . @  -      *>
                xxxxxx            :                  '::xxxxxxxxxxxx	      .     @  \                                `.'.    '---'   /.'.'   .o     >*=-    .o     o     >*=-
               :xxxx:'            :                    'xxxxxxxxxxxx:		@       .          --=         -O o       '-._         _.-' 			+   ==D	   
              .xxxxx              :                     ::xxxxxxxxxxxx		+   @  >*=-    .  *>*=-    .                  `~~~~~~~` -O---===D	o     >*=.	.     @  
              xxxx:'                                    ::xxxxxxxxxxxx	.     @  -      *>*=-    ..     @  -      *>*=-    .
              xxxx               .                      ::xxxxxxxxxxxx.	      | .     @@      | .     @@ o               .           + o               .           +      | .     
          .:xxxxxx               :                      ::xxxxxxxxxxxx::	@      | .     @o               .        o     >*=-    .o     >*=-    .o     >*=-    .   + 
          xxxxxxxx               :                      ::xxxxxxxxxxxxx:	 jgs       +   @       .     @      o     >*=-    .
          xxxxxxxx               :                      ::xxxxxxxxxxxxx:		 jgs       +   @ o               .           +       .     @      o     >*=-    .
          ':xxxxxx               '                      ::xxxxxxxxxxxx:'	jgs       +   @   jgs       +   @   jgs       +   @   
            .:. xx:.                                   .:xxxxxxxxxxxxx'		v+   @o               .           +   @ vo     >*=-    .o     >*=-    .o     >*=-    .
          ::::::.'xx:.            :                  .:: xxxxxxxxxxx':		+   @o               .   o               .           +         +   @ >*=-    .o     >*=-  
  .:::::::::::::::.'xxxx.                            ::::'xxxxxxxx':::.		.     @  -      *>*=-    ..     @  -    o     >*=-    .  *>*=-    . >*.  *>*=-  =-    .o     >*=-  		
  ::::::::::::::::::.'xxxxx                          :::::.'.xx.'::::::.	+   @	--===D	      -O o                  o     >*=-    .     +        .           + 
  ::::::::::::::::::::.'xxxx:.                       :::::::.'':::::::::		+   @	--===D	      -Oo     >*=-    .o     >*=-    .o     >*=-    .o     >*=-    .
  ':::::::::::::::::::::.'xx:'                     .'::::::::::::::::::::..	.     @  -      *>*=-    ..     @  -      *>*=-       o     >*=-    .     +  .
    :::::::::::::::::::::.'xx                    .:: :::::::::::::::::::::::	     *>*=-    ..     @  -      *>*=-         *>*=-    jgs       +   @   jgs       +   @      o	
  .:::::::::::::::::::::::. xx               .::xxxx :::::::::::::::::::::::      >*=-    .o     >   @	--===D	      - @  -      *>*=-       ov @  -      *>*=-       o
EOF
)

	trap cleanup SIGINT SIGTERM
	sudo_confirm
	clear
	log_data &
	logger_pid=$!
	echo -e "\e[1;32m$system_logo\e[0m"
	echo -e "\e[1;32m$other_logos\e[0m"
	sleep 5
	while true
	do
		clear
		choice=$(dialog --menu "Enter your choice [1-8]" 15 60 8 1 "CPU Information" 2 "GPU Information" 3 "Disk Usage and SMART Status" 4 "Memory Consumption" 5 "Network Interface Statistics" 6 "System Load Metrics" 7 "ROM Information" 8 "Exit" --stdout)
		exit_status=$?
		if [[ $exit_status -eq 1 ]]; then
			continue
		fi
		case $choice in
			1) display_cpu_info ;;
			2) display_gpu_info ;;
			3) display_disk_info ;;
			4) display_memory_info ;;
			5) display_network_info ;;
			6) display_system_load_info ;;
			7) display_rom_info ;;
			8) tput bel 
			   exit_program ;;
			*) tput bel
			   dialog --title "Invalid Choice" --msgbox "\nPlease choose from one of the listed options only." 6 60 ;;
		esac
done

