# monipi

***Please let me know if you prefer a German version of the READMEs.*** 

# How to install

If you want to use monipi.sh and its friends, go to your home directory on your Raspberry Pi and clone this repository:

```bash
cd
git clone https://github.com/ingotee/monipi.git
```

Then go into the new directory and execute install.sh. This will update Raspbian and installs gnuplot, iperf3 and some libraries and header files from the Raspbian Buster repositories. It also downloads, compiles and installs glmark2 and cpuburn-arm from GitHub. install.sh uses "sudo" because root privileges are needed e.g. for updating Raspbian. This is the reason why you will be asked for your password.

```bash
cd monipi
install.sh
```
# What is monipi?

monipi is a collection of two bash scripts and a gnuplot script. Together they enable you to examine the Raspberry Pi's behaviour regarding core temperature and ARM clock frequency with different loads. 

- monipi.sh pulls temperature and ARM frequency from the Raspberry
Pi's SoC once every second and logs them with a timestamp.
- stress-and-log.sh stresses the Raspberry Pi in three stages:
  1. openssl speed and iperf3 simulate a server that has to deal with encrypted network traffic
  2. glmark2 stresses the GPU while only giving one ARM core something to do.
  3. cpuburn-a53 stresses many units inside the ARM cores at the same time. After 50% of the time allocated for this test, glmark2 kicks in to stress the GPU simultaneously.
- howcool.pl plots temperature and ARM frequency over time. Sample images are included. 

The project came to life when it became obvious that the Raspberry Pi might be a lot faster than its predecessors, but that it also has to throttle the ARM cores a lot because they just get too hot. We wanted to know which kinds of load it can handle without throttling and how much cooling can do about it. 

# Prerequisites

1. A writable directory $HOME/monipi for the scripts, the logs and the graphs.
2. openssl compiled with the "speed" benchmark routine and ChaCha20-Poly1305. Both is the case with the stock openssl package in Raspbian Buster.
3. iperf3 from Raspbian Buster repositories
4. An iperf3-server on your local network that iperf3 can talk to. Has to be specified in the scirpt.
5. The regular Raspbian desktop should be installed.
6. glmark2 compiled with flavor x11-glesv2. You have to pull this from GitHub and compile it yourself if you do not let install.sh do it.
7. cpuburn-a53 from the project cpuburn-arm. You have to pull this from GitHub and compile it yourself if you do not let install.sh do it.
8. gnuplot from the Raspbian Buster repositories.
9. vgencmd utility included with Raspbian Buster.
 
# How to use monipi:

Go to the monipi directory

```bash
cd ~/monipi
```

You also need an iperf3 server in your network. Specify its hostname or ip address in stress-and-log.sh - the default is my computer at work which you will hopefully not be able to reach: it-mac-mini.local. To stress your Raspberry Pi, start stress-and-log.sh and give it a meaningful name for the logfile which ends up in the subdirectory LOGS.

```bash
./stress-and-log.sh RPi4B-1500MHz-MyOwnCoolingSolution
```

A normal run will take 28 minutes to complete. (You can select shorter intervals at the beginning of stress-and-log.sh.) You can plot the temperature and clock frequency afterwords. howcool.pl needs three parameters: The name of the logfile you just created, a title for the graph. You then redirect the output to a file, usually in the subdirectory GRAPHS. The format is svg which all browsers can display quite nicely.

```ḃash
./howcool.pl LOGS/RPi4B-1500MHz-MyOwnCoolingSolution.log "RPi 4B with my cool cooler" > GRAPHS/RPi4B-1500MHz-MyOwnCoolingSolution.svg
```
