#!/bin/bash
#
# monipi.sh
#
# Version 1.0 (c) c't/Ingo Storm it@ct.de - 2019-11-05
#
# Purpose: Log Raspberry Pi temperature and ARM frequency
# to stdout once per second. Usually called by a test script.
#
# Parameters: none 
#
# Prerequisites:
# - executable vcgencmd to get temp and clock from Raspberry Pi SoC
#
###################################################
#
# Release notes
#
# 2019.11.05-1400: 1.0 first release with new style

trap _cleanup SIGHUP SIGINT SIGTERM

_err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

_info() {
  echo $@
}

_dbg_info() {
  [[ ! -z "$DEBUG" ]] && echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

_cleanup() {
  # clean up when done or interrupted.
  # nothing to do at the moment.
  exit $?
}	

_check_prereq() {
  _cmd_needed="vcgencmd"
  _dbg_info "in check_prereq"
  if [ ! $(command -v $_cmd_needed) ]; then
    echo "$_cmd_needed required but not found, aborting."
    return 1
  else
    return 0
  fi
}
     
_start_logging() {
  _dbg_info "in _start_logging"
  printf "%-12s%5s%10s\n" "TIMESTAMP" "TEMP" "ARM_FREQ" 
}

_do_log() {
  local _temp                  # SoC temperature as reported by vcgencmd
  local _arm_freq              # current ARM frequency reported by vcgenmcd
  local _starttime             # system time when logging started
  local _timestamp             # temporary var for system time
  local _now                   # seconds since starttime
  local _last_second           # last second in system time

  _dbg_info "in _do_log"
  _starttime=$(date '+%s')
  
  # gather information and print a line each second 
  while true; do
    _timestamp=$(date '+%s')
    _temp=$(vcgencmd measure_temp)
    _temp=${_temp#*=}
    _temp=${_temp%\'*}
    _arm_freq=$(vcgencmd measure_clock arm)
    _arm_freq=${_arm_freq:14:(-6)}
    _now=$(( $_timestamp - $_starttime ))
    printf "%-12s%5s%10s\n" "$_now" "$_temp" "$_arm_freq"

    # wait until next system time second has started.
    # exact timing is NOT important.
    _last=$_timestamp
    while [ $_last -eq $_timestamp ]; do	
      sleep 0.1
      _timestamp=$(date '+%s')
    done
  done
}

_main() {
  _dbg_info "in main"
  if _check_prereq ; then
    _start_logging
    _do_log
  fi
}

_main  
