#!/bin/bash
#
# stress-and-log.sh
#
# Version 1.1 (c) 2019-11-06
# (c) c't/Ingo Storm it@ct.de
#
# License: GPL V3
#
# Purpose: Log Raspberry Pi temperature and ARM frequency
# while putting it under stress. The resulting logfile can
# be plotted with the gnuplot script cool.pl.
#
# Sequence of actions:
# - calculate and display entire runtime
# - start logging with monipi.sh
# - wait for $_cooldown_time seconds
# - run openssl speed and iperf3 for $_test_time seconds
# - wait for $_pause_time seconds
# - run glmark2 buffer for $_test_time seconds
# - wait for $_pause_time_seconds
# - run cpuburn-arm53 for $_test_time seconds, start
#   glmark2 buffer after $_test_time/2 while cpuburn-a53
#   is still running
# - wait for $_cooldown_time_multiplier * $_cooldown_time
# - stop logging and exit
#
# Parameters: name for the logfile 
#
# Prerequisites:
# - script monipi.sh in $HOME/monipi 
# - openssl speed with chacha20-poly1305
# - iperf3 and an iperf3 server
# - glmark2 with scene "buffer"
# - cpuburn-arm53
# - writable log directory $HOME/monipi

readonly _ARG1=$1

readonly _BASE_PATH="$HOME/monipi"                    # everything goes here
readonly _LOG_PATH="$_BASE_PATH/LOGS"                  # for logfiles
readonly _GRAPH_PATH="$_BASE_PATH/GRAPHS"             # for gnuplot graphs
readonly _MASTER_LOG="$_BASE_PATH/monipi.master.log"  # master log file
readonly _MONIPI_CMD="$_BASE_PATH/monipi.sh"	      # logging script name
readonly _OPENSSL_CMD="openssl"                       #
readonly _OPENSS_LIST_CMD="$_OPENSSL_CMD list -cipher-algorithms"
                                                      # cmd to check for cipher
readonly _OPENSSL_CIPHER="ChaCha20-Poly1305"          # the cipher we use
readonly _OPENSSL_PARAMS="speed -evp $_OPENSSL_CIPHER" # test cmd params 
readonly _IPERF3_CMD="iperf3"
readonly _IPERF3_SERVER="it-mac-mini.local"           # iperf3 server 
readonly _IPERF3_PORT="5201"			      # default port for iperf3
readonly _IPERF3_TEST_CMD="$_IPERF3_CMD -c $_IPERF3_SERVER $_IPERF3_PORT"

readonly _NC_CMD="nc"                                 # netcat
readonly _NC_TEST_CMD="$_NC_CMD -z $_IPERF3_SERVER $_IPERF3_PORT"
                                                      # netcat-command to test
                                                      # for iperf3 server
readonly _GLMARK2_CMD="glmark2-es2"
readonly _CPUBURN_CMD="$HOME/cpuburn-arm/cpuburn-a53"

_run_completed=false                      # have all tests finished?
_LOG_FILE=""                              # log file for this test

###### durations of different stress test phases

# ultra short set
#_cooldown_time=10                            # time to wait before stress tests
#_test_time=30                                # duration of each stress test
#_pause_time=20                               # pause between stress tests
#_cooldown_multiplier=2                       # multiplier for final cooldown 
# one set for short tests
#_cooldown_time=20                            # time to wait before stress tests
#_test_time=20                                # duration of each stress test
#_pause_time=30                               # pause between stress tests
#_cooldown_multiplier=3                       # multiplier for final cooldown 
# second set for regular tests, 28 minutes
_cooldown_time=60                            # time to wait before stress tests
_test_time=300                                # duration of each stress test
_pause_time=180                               # pause between stress tests
_cooldown_multiplier=2                       # multiplier for final cooldown 


trap _cleanup SIGHUP SIGINT SIGTERM

_is_cmd_there() {
  builtin type -P "$1" &> /dev/null
}

_err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

_info() {
  echo $@
}

_dbg_info() {
  [[ ! -z "$DEBUG" ]] && echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

_log_to_master() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >$_MASTER_LOG
}

_usage() {
  _info ""
  _info "usage: stress-and-log.sh logfilename"
  _info
  _info "Example: stress-and-log.sh browsertest"
  _info
  _info "will write the log to $_LOG_PATH/monipi.rowsertest.log"
  _info
}

_cleanup() {
  # clean up when done or interrupted
  # log time and name of log to master log
  if [ $_run_completed ]; then
    _log_to_master "Stress-and-log: Run completed" >>$_MASTER_LOG
  else
    _log_to_master "Stress-and-log: Run NOT completed" >>$_MASTER_LOG 
  fi
  # stop monipi.sh
    #!!! TODO stop monipi.sh in a cleaner fashion
    # kill all children including monipi.
    [[ -z "$(jobs -p)" ]] || kill $(jobs -p) 
  exit
}

_check_prereq() {
  local _req_met=1             # temporary result
  _dbg_info "in check_prereq"
  #!!! TODO
  if ! _is_cmd_there $_MONIPI_CMD; then
    _info "monipi?" $_MONIPI_CMD} "required, but not found, aborting."
  elif [ ! -w $_LOG_PATH ]; then
    _dbg_info LOG_PATH failed
    _err "Cannot write to log path $_LOG_PATH"
  elif ! _is_cmd_there $_OPENSSL_CMD ; then
    _dbg_info OPENSSL_CMD failed
    _err "openssl? $_OPENSSL_CMD required but not found, aborting."
  elif ! _is_cmd_there $_IPERF3_CMD ; then
    _dbg_info IPERF_CMD failed
    _err "iperf $_IPERF3_CMD required but not found, aborting."
  elif ! _is_cmd_there $_NC_CMD ; then
    _dbg_info NC_CMD failed
    _err "nc $_NC_CMD required but not found, aborting."
  elif ! $_NC_TEST_CMD ; then
    _dbg_info NC -z IPERF3 server failed
    _err "iperf3 server $_IPERF3_SERVER on port $_IPERF3_PORT" + \
      " unreachable, aborting."
  elif [ -z $DISPLAY ]; then
    _dbg_info No Display
    _err "DISPLAY not set. XZZ11 session needed for glmark2, aborting."
  elif ! _is_cmd_there $_GLMARK2_CMD ; then
    _dbg_info glmark2 not found
    _err "glmark2 $_GLMARK2_CMD required but not found, aborting."
  elif ! _is_cmd_there $_CPUBURN_CMD ; then
    _dbg_info No CPUBURN 
    _err "cpuburn $_CPUBURN_CMD required but not found, aborting."
  elif [ -z $_ARG1 ]; then
    _dbg_info No cmdline arg 
    _usage
  else
    _req_met=0
  fi
  if [ ! $_req_met ]; then
    err "See $_BASE_PATH/README.MD for the full requirements."
  fi
  return $_req_met
}

_fork_monipi() {
  _dbg_info "in _fork_monipi"
  $_MONIPI_CMD > $_LOG_FILE &
}

_wait() {
  while [ $(date +%s) -lt $@ ]; do
        sleep 0.34
  done
}

_start_logging() {
  _dbg_info "in start logging"
  _LOG_FILE="$_LOG_PATH/monipi.$_ARG1.log"
  printf "%-25s%-19s\n" "Logfile" $_LOG_FILE
  printf "%-20s%15s%s\n" "First cooldown" "$_cooldown_time" " seconds."
  printf "%-20s%15s%s\n" "Each pause" "$_pause_time" " seconds."
  printf "%-20s%15s%s\n" "Each test" "$_test_time" " seconds."
  printf "%-20s%15s%s\n" "Final cooldown" \
     "$(( $_pause_time * $_cooldown_multiplier ))" " seconds."
  _info ""
  _info "The output of openssl speed, iperf3 and glmark2 is not supressed so that errors can be noticed."
  _info ""
  _log_to_master "Stress-and-log started"
  _fork_monipi
}

_stop_logging() {
  _dbg_info "in stop logging"
  _run_completed=true
  _cleanup
}

_do_tests() {
  # globals: _cooldown_time, _test_time, _pause_time
  local _start_time
  local _cooldown_end
  local _openssl_time
  local _openssl_seconds
  local _first_pause_end
  local _glmark2_time
  local _second_pause_end
  local _cpuburn_time 
  local _glmark2_second_time
  local _all_end
  local _cpuburn_id

  _dbg_info "in do_tests"
  ### calculate end times of all phases
  _start_time=$(date +%s)	            # jetzt gehts los
  _start_date=$(date)
  _cooldown_end=$(( $_start_time + $_cooldown_time ))
  printf "%-20s%15s%s\n" "End of cooldown" "$_cooldown_end"
  _openssl_time=$_test_time                 # 
  printf "%-20s%15s%s\n" "openssl runtime" "$_openssl_time"
  _openssl_seconds=$(($_openssl_time/6 ))   # openssl speed does 6 runs
  printf "%-20s%15s%s\n" "openssl s/run" "$_openssl_seconds"
  printf "%15s%15s%15s\n" "_start_time" "_openssl_time" "_pause_time"
  printf "%15s%15s%15s\n" "$_start_time" "$_openssl_time" "$_pause_time"
  _first_pause_end=$(( $_start_time + $_cooldown_time + $_openssl_time + $_pause_time ))
  printf "%-20s%15s%s\n" "end 1st pause" "$_first_pause_end"
  _glmark2_time=$_test_time                 #
  printf "%-20s%15s%s\n" "glmark2 runtime" "$_glmark2_time"
  _second_pause_end=$(( $_first_pause_end \
                      + $_glmark2_time + $_pause_time ))
  printf "%-20s%15s%s\n" "end 2nd pause" "$_second_pause_end"
  _cpuburn_time=$_test_time                 #
  printf "%-20s%15s%s\n" "cpuburn runtime" "$_cpuburn_time"
  _glmark2_second_time=$(( $_cpuburn_time/2 ))
  printf "%-20s%15s%s\n" "glmark2 2nd runtime" "$_glmark2_second_time"
  _glmark2_second_start=$(( $_second_pause_end + $_glmark2_second_time ))
  printf "%-20s%15s%s\n" "glmark2 2nd start" "$_glmark2_second_start"
  _all_end=$(( $_second_pause_end + $_cpuburn_time + \
               $_pause_time * $_cooldown_multiplier ))
  printf "%-20s%15s%s\n" "end final cooldown" "$_all_end"
  _total_runtime=$(( ($_all_end - $_start_time)/60 ))
  
  ### get to work
  _info "Total runtime: " $_total_runtime " minutes."
  #!!! TODO: calculate ETA

  ### wait for $_cooldown_time to run down
  _info "Cooldown for $_cooldown_time seconds..."
  _wait $_cooldown_end

  ### run openssl speed and iperf3 simultaneously
  _info "openssl speed plus iperf3" 
  # fork iperf3
  $_IPERF3_TEST_CMD -t $_openssl_time -b 320M &
  # run openssl speed 
  $_OPENSSL_CMD $_OPENSSL_PARAMS -seconds $_openssl_seconds
  ### openssl speed and iperf3 terminate automatically

  ### wait for $_pause_time to run down
  _info "Pausing for $_pause_time seconds..."
  _wait $_first_pause_end
  
  ### run glmark2 buffer
  _info "glmark2"
  $_GLMARK2_CMD -b :duration=$_glmark2_time \
           -b buffer:columns=200:rows=40 -s 1280x960
  ### glmark2 terminates automatically
  
  ### wait for $_pause_time to run down
  _wait $_second_pause_end

  ### run cpuburn-a53 and add glmark2 after _cpuburn_time/2
  _info "cpuburn-a53 plus glmark2"
  # fork cpuburn-a53
  $_CPUBURN_CMD &
  # wait until half of $_cpuburn_time has run down
  _wait $_glmark2_second_start
  $_GLMARK2_CMD -b :duration=$_glmark2_second_time \
           -b buffer:columns=200:rows=40 -s 1280x960
  ### cpuburn-a53 has to be killed
  killall cpuburn-a53
  ### glmark2 terminates automatically
  
  ### wait for _end_cooldown_time to run down
  _info "wait for final cooldown"
  _wait $_all_end
  ### finished

}

_stress_and_log_main() {
  _dbg_info "in stress_and_log_main"
  if _check_prereq; then
    _start_logging
    _do_tests
    _stop_logging
  fi
  #!!! TODO: plot graph
  #./howcool.pl $_LOGFILE "Title" > GRAPHS/$1.svg
}  

_stress_and_log_main

