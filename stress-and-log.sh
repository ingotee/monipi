#!/bin/bash
#
# log-and-stress.sh
# Version 1.0 (c) c't/Ingo Storm it@ct.de
#
# Purpose: log Raspberry Pi temperature and ARM frequency
# while putting it under stress. The resulting logfile can
# be plotted with the gnuplot script cool.pl.
# Scenario:
# - start logging
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

MASTER_LOG="$HOME/monipi/monipi.master.log"  # master log file
LOG_FILE=""                                  # log file for this test
IPERF3_SERVER="it-mac-mini.local"
MONIPI_CMD="$HOME/monipi/monipi.stdout.sh"

# durations of different phases
_cooldown_time=20                            # time to wait before stress tests
_test_time=20                                # duration of each stress test
_pause_time=30                               # pause between stress tests
_cooldown_multiplier=3                       # multiplier for final cooldown 

# y = Dauer eines Tests
G_
# z = Cooldown am Anfang
#cooldownDauer=60
#pausenDauer=180
#testDauer=300
#cooldownDauer=60
#pausenDauer=60
#testDauer=180
cooldownDauer=20
pausenDauer=20
testDauer=30

printf "%-12s%10s\n" "Cooldown" "$cooldownDauer"
printf "%-12s%10s\n" "Pausenlänge" "$pausenDauer"
printf "%-12s%10s\n" "Testlänge" "$testDauer"

if [ -z "$1" ]; then
        echo ""
        echo "You must provide a name for the logfile as the first cmdline argument."
        echo ""
        echo "Example: log-and-stress.sh Browsertest"
        echo ""
        echo "will write the data to $HOME/monipi/monipi.Browsertest.log"
        echo ""
        exit
else
        if [ ! -d $HOME/monipi ] ; then
                mkdir $HOME/monipi
        fi
	touch "$HOME/monipi/$1"
	./monipi.sh $1 &
        logfilename="$HOME/monipi/monipi."$1".log"
        echo "Data are written to " $logfilename
        touch $logfilename
fi

# get timestamp, log it and the name of the test 
MASTER_LOG=$HOME/monipi/monipi.master.log
timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN Start" >>$MASTER_LOG

# Berechne die einzelnen Wartepunkte
startZeit=$(date +%s)	# jetzt gehts los
echo "startZeit " $startZeit
# Dauer der einzelnen Phasen
opensslDauer=$testDauer
opensslSeconds=$(( opensslDauer/6 ))
glmarkDauer=$testDauer
cpuBurnDauer=$testDauer

####### berechnete Endpunkte der Phasen
# 1. Cooldwown
erstePauseEnde=$(( $startZeit + $cooldownDauer ))
echo "erstePauseEnde " $erstePauseEnde
# nach openssl chacha + iperf
zweitePauseEnde=$(( $erstePauseEnde + $opensslDauer + $pausenDauer ))
echo "zweitePauseEnde " $zweitePauseEnde
# nach glmark
drittePauseEnde=$(( $zweitePauseEnde + $glmarkDauer + $pausenDauer ))
echo "drittePauseEnde " $drittePauseEnde
# nach cpuburn-a53
cpuBurnEnde=$(( $drittePauseEnde + $cpuBurnDauer ))
echo "cpuBurnEnde " $cpuBurnEnde
glmark2Dauer=$(( $cpuBurnDauer/2 ))
glmark2Start=$(( $drittePauseEnde + $glmark2Dauer ))
# nach cpuBurn
allEnde=$(( $cpuBurnEnde + 2*$pausenDauer ))
echo "allEnde " $allEnde
echo "****"
gesamtLaufZeit=$(( ($allEnde - $startZeit)/60 ))
echo "Gesamtlaufzeit " $gesamtLaufZeit


echo "**************" 
echo "Starting stresstest in $cooldownDauer seconds" 
date 
echo "**************" 

while [ $(date +%s) -lt $erstePauseEnde ]; do  
	sleep 0.34
done

echo "**************" 
echo "Starting iperf plus openssl speed" 
date 
echo "**************" 
timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN iperf plus openssl start" >>$MASTER_LOG
#iperf3 -t $opensslDauer -c ingos-mac-mini.local
iperf3 -t $opensslDauer -b 320M -c ingos-mac-mini.local &
openssl speed -evp chacha20-poly1305 -seconds $opensslSeconds
#killall iperf3
timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN openssl chacha20-poly1305 finished" >>$MASTER_LOG
timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN iperf plus openssl finished" >>$MASTER_LOG

# Pause, bis insgesamt Pause+2*openSSL+Pause um sind
while [ $(date +%s) -lt $zweitePauseEnde ]; do  
	sleep 0.34
done

echo "**************" 
echo "running glmark2 buffer for $glmarkDauer seconds" 
date 
echo "**************" 
timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN glmark2 start" >>$MASTER_LOG

glmark2 -b :duration=$glmarkDauer -b buffer:columns=200:rows=40 -s 1280x960

timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN glmark2 finished" >>$MASTER_LOG
echo "**************" 
echo "Done with glmark2 buffer - waiting " 
date 
echo "**************" 

# Pause
while [ $(date +%s) -lt $drittePauseEnde ]; do  
	sleep 0.34
done

echo "**************" 
echo "Starting cpuburn-a53" 
date 
echo "**************" 
timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN cpuburn-a53 start" >>$MASTER_LOG
cpuburn-a53 &

# Pause, bis die Hälfte der Zeit des CPU-Burn um ist
while [ $(date +%s) -lt $glmark2Start ]; do  
	sleep 0.34
done

echo "**************" 
echo "Starting cpuburn-a53 plus glmark" 
date 
echo "**************" 
timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN cpuburn-a53 plus glmark start" >>$MASTER_LOG

# schalte glmark2 dazu
glmark2 -b :duration=$glmark2Dauer -b buffer:columns=200:rows=40 -s 1280x960
killall cpuburn-a53
timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN cpuburn-a53 plus glmark finished" >>$MASTER_LOG

echo "**************" 
echo "end of cpuburn-a53 plus glmark" 
date 
echo "**************" 

while [ $(date +%s) -lt $allEnde ]; do  
	sleep 0.34
done

timestamp=$(date '+%s')
echo "$timestamp" "BURN-IN finished" >>$MASTER_LOG

echo "**************" 
echo "this is the end"
date 
echo "**************" 

rm "$HOME/monipi/$1"

#./cool6.pl monipi/monipi.$1.log -p > $1.svg



 
