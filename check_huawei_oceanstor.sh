#!/bin/bash
# Author:       Jurij Vasiliev
# Date:         10.09.2018
# Version       1.2.0
#
# This plugin was originally made to check the hardware of IBM V7000 and was developed by Lazzarin Alberto.
# Now it is adapted by Jurij Vasiliev to check the hardware status of Huawei OceanStor.
# To use it you need to add user and ssh key on the OceanStor and your Linux machine.
# Try to log from linux machine to the OceanStor without password, if it succeeds you can use the plugin.
# The help is included in the script.
#
#
# CHANGELOG
# 1.2.0 10.09.2018 by Alexander Golikov
# Version without TMP-Files, also modified ssh options with path to ssh-key
#
# 1.1.0 22.05.2018
# Added support for checking SSH connections + few code changes and indents
#
# 1.0.3 18.05.2018
# Auto add storage system to known hosts
#
# 1.0.2 15.05.2018
#  1. Added support for multiple statuses
#  2. Rewrited all checks
#  3. Changed the temp file initialization
#
# 1.0.1 18.04.2018
# Minor changes in CRITICAL and WARNING displays
#
# 1.0.0 17.04.2018
# First release after original script rebuild.
#
#
#
# SSH client binary file with auto add to known_hosts
ssh='/usr/bin/ssh -o StrictHostKeyChecking=no -i /etc/nagios/sshkey/oceanstor'

# Standard exit code is 0
exit_code=0

# OceanStor failed Health and Running status
failed_health_status="(Offline|Pre-fail|Fault|--)"
failed_running_status="(Offline|Reconstruction|--)"

# variable with output info for nagios
output_info=""

# Get options from command
while getopts 'H:U:c:d:h' OPT; do
  case $OPT in
    H)  storage_system=$OPTARG;;
    U)  user=$OPTARG;;
    c)  command=$OPTARG;;
    h)  help="yes";;
    *)  unknown="yes";;
  esac
done

# temp file for status
#tmp_file=/var/tsmp/oceanstor_$storage_system_$command.$(date +%s).tmp
tmp_var=""

# usage guide
HELP="
Check Huawei OceanStor through ssh

usage: $0 [ -M value -U value -Q command -h ]

syntax:

-H --> IP Address
-U --> user
-c --> command to storage
  lslun - show lun general status
  lsdisk - show disk general status
  lsdiskdomain - show disk_domain general status
  lsexpansionmodule - show expansiom module status
  lsinitiator - show initiator status (prints alias name for initiator)
  lsstoragepool - show storage_pool general status
-h --> Print this help screen

Note:
This check uses ssh protocol.
"

# If -h and wrong arg then show help guide
if [ "$help" = "yes" -o $# -lt 1 ]; then
  echo "$HELP"
  exit 0
fi

########################## FUNCTIONS ##########################

function check_tmp_var {
  if [ -z "$tmp_var" ]; then
    output_info=" $1"
    echo -ne "$output_info\n"
    exit 1
  fi
}

########################## MAIN CODE ##########################

case $command in
  lslun)
    tmp_var=$($ssh $user@$storage_system 'show lun general' |sed '1,4d')

    check_tmp_var "WARNING: There are no LUNs or your SSH key/connection is wrong"

    cat_status=$(echo "$tmp_var" |awk '{printf $5}' |grep -E "$failed_health_status")
    if [ "$?" -eq "0" ]; then
      output_info="$output_info CRITICAL: check your LUN status \n"
    else
      output_info="$output_info OK: All LUNs Online \n"
    fi

    while read line
    do
      lun_name=$(echo "${line}" | awk '{printf $2}')
      lun_status=$(echo "${line}" | awk '{printf $5}')

      if [ $lun_status = "Normal" ]; then
        output_info="$output_info OK: LUN $lun_name status: $lun_status \n"
      else
        output_info="$output_info ATTENTION: LUN $lun_name status: $lun_status \n"
        exit_code=2
      fi

    done < <(echo "$tmp_var")
  ;;

  lsdisk)
    tmp_var=$($ssh $user@$storage_system 'show disk general' |sed '1,4d')

    check_tmp_var "WARNING: There are no DISKs or your SSH key/connection is wrong"

    cat_status=$(echo "$tmp_var" |awk '{printf $2}' |grep -E "$failed_health_status")
    if [ "$?" -eq "0" ]; then
      output_info="$output_info CRITICAL: check your DISK status \n"
    else
      output_info="$output_info OK: All DISKs Online and Healthy \n"
    fi

    drive_total=$(echo "$tmp_var" |/usr/bin/wc -l)
    while read line
    do
      drive_n=$(echo "${line}" | awk '{printf $1}')
      drive_status=$(echo "${line}" | awk '{printf $2}')
      drive_role=$(echo "${line}" | awk '{printf $6}')
      drive_type=$(echo "${line}" | awk '{printf $4}')
      drive_capacity=$(echo "${line}" | awk '{printf $5}')
      drive_slot=$(echo "${line}" | awk '{printf $1}')

      if [ $drive_status = "Normal" ]; then
        output_info="$output_info OK: Disk $drive_n is online \n"
      else
        output_info="$output_info ATTENTION: Disk $drive_n \nstatus: $drive_status \nrole: $drive_role \ntype: $drive_type \ncapacity: $drive_capacity \nenclosure: $drive_enclosure \nslot: $drive_slot \n"
        exit_code=2
      fi

    done < <(echo "$tmp_var")
  ;;

  lsdiskdomain)
    tmp_var=$($ssh $user@$storage_system 'show disk_domain general' |sed '1,4d')

    check_tmp_var "WARNING: There are no DISK DOMAINs or your SSH key/connection is wrong"

    cat_status=$(echo "$tmp_var" |awk '{printf $3}' |grep -E "$failed_health_status")
    if [ "$?" -eq "0" ]; then
      output_info="$output_info CRITICAL: check your DISK DOMAIN status \n"
    else
      output_info="$output_info OK: All DISK DOMAINs Online \n"
    fi

    while read line
    do
      disk_domain_name=$(echo "${line}" | awk '{printf $2}')
      disk_domain_health_status=$(echo "${line}" | awk '{printf $3}')
      disk_domain_running_status=$(echo "${line}" | awk '{printf $4}')

      if [ $disk_domain_health_status = "Normal" ]; then
        output_info="$output_info OK: DISK DOMAIN $disk_domain_name Health status: $disk_domain_health_status with Running status: $disk_domain_running_status \n"
      else
        output_info="$output_info ATTENTION: DISK DOMAIN $disk_domain_name Health status: $disk_domain_health_status with Running status: $disk_domain_running_status \n"
        exit_code=2
      fi

    done < <(echo "$tmp_var")
  ;;

  lsexpansionmodule)
    tmp_var=$($ssh $user@$storage_system 'show expansion_module' |sed '1,4d')

    check_tmp_var "WARNING: There are no EXPANSION MODULEs or your SSH key/connection is wrong"

    cat_status=$(echo "$tmp_var" |awk '{printf $2}' |grep -E "$failed_health_status")
    if [ "$?" -eq "0" ]; then
      output_info="$output_info CRITICAL: check your EXPANSION MODULE status \n"
    else
      output_info="$output_info OK: All EXPANSION MODULES are Online \n"
    fi

    while read line
    do
      expansion_mod_id=$(echo "${line}" | awk '{printf $1}')
      expansion_mod_health_status=$(echo "${line}" | awk '{printf $2}')
      expansion_mod_running_status=$(echo "${line}" | awk '{printf $3}')

      if [ $expansion_mod_running_status = "Running" ]; then
        output_info="$output_info OK: EXAPNSION MODULE $expansion_mod_id Health status: $expansion_mod_health_status with Running status: $expansion_mod_running_status \n"
      else
        output_info="$output_info ATTENTION: EXPANSION MODULE $expansion_mod_id Health status: $expansion_mod_health_status with Running status: $expansion_mod_running_status \n"
        exit_code=2
      fi

    done < <(echo "$tmp_var")
  ;;

  lsinitiator)
    tmp_var=$($ssh $user@$storage_system 'show initiator' |sed '1,4d')

    check_tmp_var "WARNING: There are no INITIATORs or your SSH key/connection is wrong"

    cat_status=$(echo "$tmp_var" |awk '{printf $2}' |grep -i Offline)
    if [ "$?" -eq "0" ]; then
      output_info="$output_info CRITICAL: INITIATOR OFFLINE \n"
    else
      output_info="$output_info OK: All INITIATORs Online \n"
    fi

    while read line
    do
      initiator_name=$(echo "${line}" | awk '{printf $4}')
      initiator_running_status=$(echo "${line}" | awk '{printf $2}')

      if [ $initiator_running_status = "Online" ]; then
        output_info="$output_info OK: INITIATOR $initiator_name status: $initiator_running_status \n"
      else
        output_info="$output_info ATTENTION: INITIATOR $initiator_name status: $initiator_running_status \n"
        exit_code=2
      fi

    done < <(echo "$tmp_var")
  ;;

  lsstoragepool)
    tmp_var=$($ssh $user@$storage_system 'show storage_pool general' |sed '1,4d')

    check_tmp_var "WARNING: There are no STORAGE POOLs or your SSH key/connection is wrong"

    cat_status=$(echo "$tmp_var" |awk '{printf $5}' |grep -E "$failed_health_status")
    if [ "$?" -eq "0" ]; then
      output_info="$output_info CRITICAL: Check your STORAGE POOL status \n"
    else
      output_info="$output_info OK: All STORAGE POOLs Online \n"
    fi

    while read line
    do
      spool_name=$(echo "${line}" | awk '{printf $2}')
      spool_health_status=$(echo "${line}" | awk '{printf $4}')
      spool_running_status=$(echo "${line}" | awk '{printf $5}')

      if [ $spool_running_status = "Online" ]; then
        output_info="$output_info OK: STORAGE POOL $spool_name Health status: $spool_health_status with Running status: $spool_running_status \n"
      else
        output_info="$output_info ATTENTION: STORAGE POOL $spool_name Health status: $spool_health_status with Running status: $spool_running_status \n"
        exit_code=2
      fi

    done < <(echo "$tmp_var")
  ;;

  *)
    echo -ne "Command not found. \n"
    exit 3
  ;;
esac

#rm $tmp_file
echo -ne "$output_info\n"
exit $exit_code
