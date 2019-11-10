#!/bin/bash
#
# install.sh
#
# Beta-Version 0.9b (c) 2019-11-10
# (c) c't/Ingo Storm it@ct.de - 2019-11-10
# 
# License: GPL V3
#
# !!!! Warning: This is a first shot. Use with caution!
# !!!! Please report problems via GitHub or directly via
# !!!! e-mail to it@ct.de
#
# Purpose: Install software requiered for the stress test
#   an monitoring scripts monipi.sh, stress-and-log.sh,
#   howcool.pl.
#
# Parameters: none 
#
# Prerequisites:
# - Installation needs root access, so the script calls sudo
#   a couple of times. You will have to enter your password,
#   possibly several times. If you start this script via sudo,
#   you should only be asked once.
#  
#   "sudo ./install.sh"
###################################################
#
# Release notes
#
# 2019.11.10-1400: 0.9b first release 

trap _cleanup SIGHUP SIGINT SIGTERM

_err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

_info() {
  echo $@
}

_info_n() {
  echo -n $@
}

_dbg_info() {
  [[ ! -z "$DEBUG" ]] && echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

_cleanup() {
  # clean up when done or interrupted.
  # nothing to do at the moment.
  exit $?
}	

_is_cmd_there() {
  builtin type -P "$1" &> /dev/null
}

_apt_install() {
  _info_n "Checking for $1..."
  if _is_cmd_there "$1"; then 
    _info " ok."
  else
    _info "Installing $1..."
    _info ""
    sleep 2
    sudo apt install $1
    # if you know a smarter way to check if the installation
    # was successful, please let me know or create a pull request.
    # Thank you!
    #
    if _is_cmd_there "$1"; then 
      _info " ok."
      return 0
    else
      _err "Installing $1 failed. Aborting."
      exit 1
    fi
  fi
}

_check_glmark2() {
  if _is_cmd_there "glmark2"; then 
    _info " ok."
  else
    _info " not found. Cloning it from GitHub."
    cd;
    git clone "https://github.com/glmark2/glmark2.git"
    if [ $? ]; then
      _info ""
      _info "Cloned successfully."
      _info "Configuring it..."
      cd "$HOME/glmark2"
      ./waf configure --with-flavors=x11-glesv2 | tee .my_config.log 
      if tail -1 .my_config.log | grep "successfully" 1>/dev/null ; then
        _info ""
        _info "Configuration successful. Compiling now."
        _info ""
        sleep 10
        ./waf
        if [ -x "build/src/glmark2" ]; then
          _info "Compile seems to have been successful. Installing now."
          _info ""
          sleep 2
          sudo ./waf install
          _info ""
          if _is_cmd_there "glmark2"; then 
            _info "Installion successful."
          else
            _err "Installing glmark2 failed. Aborting."
            exit 1
          fi
        else
          _err "Compiling glmark2 failed. Aborting."
          exit 1
        fi
      else
        _err "Configuring glmark2 failed. Aborting."
        exit 1
      fi
    else
      _err "Cloning glmark2 failed. Aborting."
      exit 1
    fi
  fi
}

_check_cpuburn-a53() {
  if _is_cmd_there "$HOME/cpuburn-arm/cpuburn-a53"; then 
    _info " ok."
  else
    _info " not found. Cloning it from GitHub."
    cd
    git clone https://github.com/ssvb/cpuburn-arm.git
    if [ $? ]; then
      _info ""
      _info "Cloned successfully."
      _info "Compiling it..."
      _info ""
      sleep 2
      cd "$HOME/cpuburn-arm"
      gcc -o cpuburn-a53 cpuburn-a53.S
      if _is_cmd_there "$HOME/cpuburn-arm/cpuburn-a53"; then
        _info " Compiled ok."
      else
        _err "Compiling cpuburn-a53 failed. Aborting"
        exit 1
      fi
    else
      _err "Cloning failed. Aborting."
      exit 1
    fi
  fi
}
      
_do_install() {
  _dbg_info "in install main"
  _info "Updating Raspian first..."
  _info ""
  _info "Running sudo apt update && sudo apt upgrade"
  _info ""
  sleep 2
  sudo apt update && sudo apt upgrade
  _info ""
  _info "Installing some header files needed for compiling glmark2 ..."
  _info ""
  sleep 2
  sudo apt install libjpeg-dev libx11-dev libpng12-dev
  _info ""
  _info_n "Checking for vcgencmd..."
  if _is_cmd_there "vcgencmd"; then 
    _info " ok."
  else
    _err "vcgencmd is needed, but cannot be found."
    _err "Have you removed the package libraspberrypi-bin?"
    _err "Please re-install it."
    exit 1
  fi
  # Checking for gnuplot
  _apt_install gnuplot
  # Checking for iperf3
  _apt_install iperf3
  _info ""
  _info "Checking for glmark2..."
  _check_glmark2 
  _info "Checking for cpuburn-a53..."
  _check_cpuburn-a53    
}

_install_main() {
  _do_install
  _info "Done. Thank you for your patience and co-operation."
}

_install_main  
