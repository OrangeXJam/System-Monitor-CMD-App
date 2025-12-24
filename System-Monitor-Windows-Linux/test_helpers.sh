#!/bin/bash
#=========================================
# Unit Testing Helper Functions
#=========================================

# Source your main system monitor script (without executing main)
source ./SM.sh

echo "==== UNIT TESTING HELPER FUNCTIONS ===="

# Helper function to check if variable is non-empty
check_var() {
    local var_name=$1
    local var_value=$2
    if [[ -n "$var_value" ]]; then
        echo "PASS: $var_name"
    else
        echo "FAIL: $var_name"
    fi
}

#-----------------------------------------
# Test CPU info
#-----------------------------------------
get_cpu_info
check_var "cpu_model" "$cpu_model"
check_var "cpu_usage" "$cpu_usage"
check_var "cpu_temp_display" "$cpu_temp_display"

#-----------------------------------------
# Test GPU info
#-----------------------------------------
get_gpu_info
check_var "gpu_model" "$gpu_model"
check_var "igpu_model" "$igpu_model"
check_var "gpu_usage" "$gpu_usage"
check_var "igpu_usage" "$igpu_usage"
check_var "gpu_temp_display" "$gpu_temp_display"

#-----------------------------------------
# Test Disk info
#-----------------------------------------
get_disk_info
check_var "disk_info_aggregated" "$disk_info_aggregated"

#-----------------------------------------
# Test Memory info
#-----------------------------------------
get_memory_info
check_var "memTotal" "$memTotal"
check_var "memUsed" "$memUsed"
check_var "memAvail" "$memAvail"

#-----------------------------------------
# Test Network info
#-----------------------------------------
get_network_info
check_var "network_details" "$network_details"

#-----------------------------------------
# Test System Load info
#-----------------------------------------
get_system_load_info
check_var "num_of_users" "$num_of_users"
check_var "tasks" "$tasks"
check_var "uptime_hours" "$uptime_hours"

#-----------------------------------------
# Test ROM info
#-----------------------------------------
get_rom_info
check_var "rom_vendor_version" "$rom_vendor_version"
check_var "rom_revision" "$rom_revision"
check_var "rom_size" "$rom_size"
check_var "rom_date" "$rom_date"
check_var "kernel" "$kernel"

echo "==== UNIT TESTING COMPLETED ===="

