#!/usr/bin/gnuplot -c 
#
# howcool.pl
#
# Version 1.0 (c) 2019-11-07
# (c) c't/Ingo Storm it@ct.de
# 
# License: GPL V3
#
# Purpose: Plot temperature and ARM frequency data gathered by
#   monipi.sh
#
# Parameters: - name of logfile 
#             - graph title
#
###################################################

### plot to an SVG file
set terminal svg size 1200 960 font ",20"
### title is read from cmdline
set title ARG2 
set title font ",36" norotate
set timestamp "%d.%m.%Y %H:%M" top font ",10"
set datafile separator whitespace
set border lw 2
## x axis: time
set xtics font ",16" border out nomirror 0,150
set xlabel "Zeit [s]" font ",20" 
set mxtics 
### y axis: ARM clock frequency
set yrange [ 0 : 2200.00 ] 
set ylabel "ARM-Taktfrequenz [MHz]" font ",20" rotate
set ytics font ",16" textcolor rgb "#00AA00" border out nomirror
### secondary y axis: temperature
set y2label "Core-Temperatur [°C]" font ",20" rotate offset -2,0
set y2range [ 0 : 100 ] 
set y2tics font ",16" textcolor rgb "#990000" border out nomirror
### Legende zweispaltig unten rechts im Plot
set key font ",24" right bottom maxcolumns 2 maxrows 2 
plot ARG1 using 2 title "Temperatur" axes x1y2 with lines lw 1 lc rgb "#990000",\
     ARG1 using 3 title "Takt" axes x1y1 with lines lw 1 lc rgb "#00AA00",\
     85 axes x1y2 w lines lc rgb "#990000" lt 2 lw 2 dt 2 title "85 °C",\
     80 axes x1y2 w lines lc rgb "#990000" lt 0 lw 1 dt 2 title "80 °C"
# EOF
