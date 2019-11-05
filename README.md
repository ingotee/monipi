# monipi

monipi is a collection of two bash scripts and a gnuplot script. Together they enable you to examine the Raspberry Pi's behaviour regarding core temperature and ARM clock frequency with different loads. 

- monipi.sh pulls temperature and ARM frequency from the Raspberry
Pi's SoC once every second and logs them with a timestamp.
- stress-and-log.sh stresses the Raspberry Pi in three stages:
  1. openssl speed and iperf3 simulate a server that has to deal with encrypted network traffic
  2. glmark2 stresses the GPU while only giving one ARM core something to do.
  3. cpuburn-a53 stresses many units inside the ARM cores at the same time. After 50% of the time allocated for this test, glmark2 kicks in to stress the GPU simultaneously.
- howcool.pl plots temperature and ARM frequency over time. Sample images are included. 

The project came to life when it became obvious that the Raspberry Pi might be a lot faster than its predecessors, but that it also has to throttle the ARM cores a lot because they just get too hot. We wanted to know which kinds of load it can handle without throttling and how much cooling can do about it. 

Prerequisites:

1. A writable directory $HOME/monipi for the scripts, the logs and the graphs.
2. openssl compiled with the "speed" benchmark routine and ChaCha20-Poly1305. Both is the case with the stock openssl package in Raspbian Buster.
3. iperf3 from Raspbian Buster repoistories
4. glmark2 compiled with x11-???. You have to pull this from GitHub and compile it yourself if you do not let install.sh do it.
5. cpuburn-a53 from the project cpuburn-arm. You have to pull this from GitHub and compile it yourself if you do not let install.sh do it.
6. gnuplot from the Raspbian Buster repositories.
7. vgencmd utility included with Raspbian Buster.
 
install.sh can try and gather what might be missing on your Raspberry Pi.

