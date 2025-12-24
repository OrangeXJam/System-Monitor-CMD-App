#!/bin/bash

SCRIPT_NAME="SM.sh"
DOCKER_IMAGE_NAME="system-monitor:v1"
LOG_DIR_NAME="monitor_logs"
declare -A TOOL_MAP=(
["dmidecode"]="dmidecode"
    ["smartctl"]="smartmontools"
    ["dialog"]="dialog"
    ["lshw"]="lshw"
    ["sensors"]="lm-sensors"
    ["lspci"]="pciutils"
    ["ip"]="iproute2"
    ["nmcli"]="network-manager"
    ["nvidia-smi"]="nvidia-driver"
)

check_and_install_dependencies() {
	echo "Checking Linux Dependencies."
    
    	local INSTALL_CMD=""
    	if command -v apt &> /dev/null; then
        	INSTALL_CMD="sudo apt install -y"
    	elif command -v yum &> /dev/null; then
        	INSTALL_CMD="sudo yum install -y"
    	else
        	echo "No recognized package manager (apt or yum) found. Cannot check dependencies."
        	return 1
    	fi

    	local MISSING_TOOLS=()
    	for command_name in "${!TOOL_MAP[@]}"; do
        	if ! command -v "$command_name" &> /dev/null; then
        		MISSING_TOOLS+=("${TOOL_MAP[$command_name]}")
        	fi
    	done

    	if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        	echo ""
        	echo "Missing dependencies detected: ${MISSING_TOOLS[*]}"
        	echo "Please enter your password for the installation."
        	while ! sudo -n true 2>/dev/null; do
				echo "Authentication required. Please enter your sudo password: "
				read -r -s SUDO_PASS
				echo "$SUDO_PASS" | sudo -S true 2>/dev/null
            		if [ $? -eq 0 ]; then
                		echo "Authentication successful."
                		break
           		else
                		echo "Password incorrect. Please try again."
            		fi
        	done

        	echo "Starting installation. . ."
        	echo "$INSTALL_CMD ${MISSING_TOOLS[*]}"
        	$INSTALL_CMD "${MISSING_TOOLS[@]}"
        
        	if [ $? -eq 0 ]; then
        		echo "Dependencies installed successfully."
        	else
        		echo "Failed to install one or more dependencies, check network and permissions"
            		return 1
        	fi
    	else
        	echo "All required dependencies installed successfully."
    	fi
    	return 0
}

if [ ! -d "$LOG_DIR_NAME" ]; then
	mkdir -p "$LOG_DIR_NAME"
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if [[ "$(uname -s)" == "Linux" ]]; then
	echo "Linux Host Detected, running script directly."
    	if check_and_install_dependencies; then
    		sleep 5
        	./"$SCRIPT_NAME"
   	else
        	echo "Dependency error, Aborting execution."
        	exit 1
   	fi
else
    	echo "Non Linux system detected, running Docker."
    	if ! command -v docker &> /dev/null; then
        	echo "Docker is required for the program to run. Please install Docker from their official site"
        	echo "https://docs.docker.com/desktop/"
        	exit 1
    	fi
    	echo "Local log directory created: $LOG_DIR_NAME"
    	
    	echo "Building Docker Image: $DOCKER_IMAGE_NAME..."
    	docker build -t "$DOCKER_IMAGE_NAME" .
    	echo "Running Container; Logs will be saved to: $LOG_DIR_NAME"
    	
    	docker run -it --rm \
        --name my_system_monitor \
        --pid=host \
        --net=host \
        --cap-add=ALL \
        -v /dev:/dev \
        -v "$(pwd)/$LOG_DIR_NAME":/app \
        "$DOCKER_IMAGE_NAME"
fi
