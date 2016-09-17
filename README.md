# Datascience Sandbox Server Installation
Collection of scripts and configuration files to quickly setup a Datascience **sandbox server** to learn/experiment with Big Data and Machine Learning / Deep Learning softwares (including **Tensorflow with support for the latest Nvidia Pascal GPU GTX1080**)


## Introduction

As I am learning/experimenting with Big Data and Machine Learning, I sometimes need to quickly setup/clone/restore a sandbox server with some various Data Science softwares. This collection of scripts/configurations files is intended to facilitate/automate this task. You can use it "as this", modify it to suit your project's requirements or simply get directions from it for a manual server installation.

This script has been updated/tested with the very great **Innovation Lab Projet #1521** proposed by **OVH** (see https://www.runabove.com/index.xml) which consists in a dedicated server with the following configuration : 2x Intel Xeon E5-2630v3 (16 cores each / 32 cores in total), 128GB of RAM, 240 GB of SSD, 1 Nvidia GTX 1080 

## What it does :

From a fresh installation of Ubuntu,

- update ubuntu, setup a firewall, create a user, ...
- provide an option to setup a **Nvidia Pascal GTX1080** on Ubuntu 14.04 (Install drivers + cuda 8.0) 
- provide an option to install (compile sources) **Tensorflow r0.10 (with or without Nvidia GPU support)** 
- provide an option to install **Torch** 
- provide an option to install **Hadoop 2.7 / Spark 2.0** as a Mono-cluster
- install some tools like x2go server to be able to open program like Firefox or R Studio through a ssh remote connection
- provide an option to install **R and R Studio Server** 
- provide an option to install **R and R Studio Desktop** 
- provide an option to install **Let's Encrypt SSL certificates for R Studio Server and Hadoop/Spark** 
- provide an option to install miniconda 

## Requirements

* Ubuntu 14.04 LTS (with original kernel 3.13.0-95)
* If you want to setup the **Nvidia graphic card**, you will have to download the following softwares from Nvidia website (you might need to register a free account and enroll to some Nvidia free developpers programs). Note, these versions are the latest available at the time of writing these scripts : 
   * NVIDIA-Linux-x86_64-367.44.run* (see :http://www.nvidia.com/drivers )
   * cuda_8.0.27_linux.run* (see : https://developer.nvidia.com/cuda-release-candidate-download  )
   * cuda_8.0.27.1_linux.run* (see : https://developer.nvidia.com/cuda-release-candidate-download )
   * cudnn-8.0-linux-x64-v5.1.tgz (see : https://developer.nvidia.com/cudnn )

* The *setup-server.sh* script and *install* directory (and its content) need to be installed in a */root/Datascience-Sandbox-Installation/* directory. You might change the location or rename the directory, but in that case you will have to update the location in the *ressources* variable defined at the begining of the *setup-server.sh* script (Make sure the *.run* scripts are executable (*chmod u+x *.run*)). 
  
   *  *setup-server.sh* is the main installation script. (Note : A user account will be created. By default it is named hduser (in group: haddoop) The user login ID and group are defined in a variable at the begining of the script if you want to change it. You will be prompted by the install script to define the password of this user login)
   *  the *install* directory contains aditional scripts and configuration files to be restored/installed
   *  Optional / Not available in this github repository : you can create a *install/perso* sub-directory where you can store your own archive of *.ssh/* directory for your 'default' user login if you want to later automate the restoration of your ssh keys for that user. If no *install/perso/ssh.tar* archive exists, the script will generate new ssh keys for the new user login being created by the script, otherwise it will restore its keys from that tar archive). 
       
   *  Optional / Not available in this github repository : if your server has a *Nvidia graphic card (the script is written for the GTX1080)* , you can create a *install/nvidia* sub-directory to downaload/store the required Nvidia installers  described abobe so that the installation script can find them.
   

Note : The installation script will install x2go server and Firefox. You can use x2goclient from your remote connection to launch Firefox (specific app */usr/bin/firefox* , you do not have to launch a full X windows desktop) to make it easier to download the Nvidia softwares after login to the Nvidia website, accept the conditions of utilisations and programs registration. This is also usefull to access the Hadoop/Yarn/Spark admin pages without opening them on the firewall. All the more, if you want to execute R Studio Destktop on the server you will need to use it through x2go client too. See http://wiki.x2go.org/doku.php/download:start in order to  download/install the x2go client


## Usage : setup a Datascience sandbox

**For the first time, it is higly encouraged to have a look at *setup-server.sh* code in order to understand what is executed and decide to use it 'as this' or adjust/modify the code before using it.** The code is divided in blocks of code that reflects the different options available (In fact this script is some kind of concatenation of different products installation I performed over the time. You can think of it as a swiss-knive-tool to setup a new sandbox server) 

You can retrieve the script from github by cloning this repository (you might have to install git first)
 ```shell
 git clone https://github.com/fdasilva59/Datascience-Sandbox-Installation
 ```

```shell
root@BigServer:~#/root/Datascience-Sandbox-Installation/setup-server.sh [options]
```
You can use the following installation parameters : 

```shell
    --cuda            to install Nvidia GTX1080 drivers, CUDA 8 and cuDNN 
                      (Nvidia GPU option will be enabled when installing Tensorflow and/or Torch)
    --tensorflow      to install TensorFlow 
    --torch           to install Torch 
    --hadoop          to install Hadoop/Yarn/Spark (Mono cluster / Sandbox)
    --letsencrypt     to install Let's Encrypt (and manage free SSL certificates for R Studio Server and Hadoop)
                      (You need to provide a valid domain name for your server)
    --rserver         to install R and R Studio Server (To be used through a Browser)
    --rdesktop        to install R and R Studio Desktop (To be used through a x2GoClient connection (via SSH)
    --conda           to install miniconda 
    --help            to display this help menu 
```

Suggestion of configuration  : 

 * **Deep Learning :  Tensorflow and Torch with Nvidia Cuda support**, execute (don't forget to retrieve nvidia installers before) :

      `./setup-server.sh --cuda --tensorflow --torch`

 * Big Data : R Studio Server (with SSL access), Hadoop/Spark (mono cluster/sandbox) :

      `./setup-server.sh  --hadoop --letsencrypt --rserver`

 * Full Data Science Sandbox : 

      `./setup-server.sh --cuda --tensorflow --torch --hadoop --letsencrypt --rserver`


The script requires to be executed by the root user. 


When new version of the softwares will be available, you should be able to use them by updating a few variables at the begining of the *setup-server.sh* script

Once installed, you can remove the *setup-server.sh* and *install/* directory (and contents)


## Limitations

This script has been developped for Ubuntu 14.04 It has not been tested on other version/linux flavors
(I did not choose Ubuntu 16 because there are issues with x2go for the moment)

**The installation script was not designed/intended to setup a production server** : it just aims to setup a development sandbox (that suits my needs). All the more installing Haddop on a single node does not make any sense apart from learning Hadoop in a sandbox (Eventually, you can consider installing Spark without Haddop, as this kind of OVH server has many cores/lots of RAM). Anyway you can clone/use/adjust/correct/complete this script if you find it usefull for your needs.

The installation script is not intended to be executed several times (like to update a previous setup). Though it should work in most cases properly, not every cases have been tested. So if you want to use it after an initial setup, use it with caution at your own risks.

** Let's Encrypt ** : It is highly recommended to protect the access to the admin pages of Hadoop/Spark or to R Studio Server via SSL access. In order to do so *you have to own/buy/provide a valid domain name* for your server (See Let's Encrypt section below)

** BACKUP ** As usual, don't forget to backup data on you server, following the installation. In particular, if you you have generated Let's Encrypt SSL certificates, make a backup on another location ! 

## Note about Nvidia GTX1080 setup and Tensorflow compilation with CUDA option

**The script takes care of everything described below, but in case you would like to install your system manually, here are a couple of usefull things to know** (It took me a little bit of times to figure out them, as it was the first time I installed a Nvidia GPU on Ubuntu, especially with some Nvidia release candidate softwares)

A good starting point for me was this blog post from Nvidia website : http://www.nvidia.com/object/gpu-accelerated-applications-tensorflow-installation.html

Another good source of information was the TensorFlow website itself : https://www.tensorflow.org/versions/r0.10/get_started/os_setup.html#installing-from-sources

First, you must install the GPU drivers. Some Nvidia drivers exist in Ubuntu repository but you must not install them (*apt-get install nvidia-\* *)  for the moment, as the versions for the Pascal architecture are currently only available from Nvidia website. Mixing the packages installation lead to some faillure when installing the Nvidia drivers (and sometimes the errors are not very visible...) 

you can check that the Nvidia drivers are correctly installed by running this command
```shell
$ nvidia-smi 
      
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 367.44                 Driver Version: 367.44                    |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GeForce GTX 1080    Off  | 0000:04:00.0     Off |                  N/A |
|  0%   33C    P0    39W / 180W |      0MiB /  8113MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID  Type  Process name                               Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
$ 
```

Also prior to installing the Nvidia drivers, the Linux kernel sources (generic) corresponding to the used kernel needs to be installed. 

Then, I met compilation issues in Tensorflow when compiling with the cuda option. I found some tips on the issue here : https://github.com/tensorflow/tensorflow/issues/3431#issuecomment-234131699 
So I used awk to patch one Tensorflow source file in order to add the line `cxx_builtin_include_directory: "/usr/local/cuda-8.0/include" ` in the file `tensorflow/third_party/gpus/crosstool/CROSSTOOL` 

Note that it did not worked if I used the */usr/local/cuda* unix link that points to the actual directory */usr/local/cuda-8.0*


If you go for a manual installation, here is what the script is executing :


```shell

########  With user root

# Update the system
apt-get -y  install software-properties-common
add-apt-repository -y universe
apt-add-repository -y multiverse
add-apt-repository -y ppa:webupd8team/java
apt-get  update
apt-get -y  upgrade

# Install Java
apt-get -y  install oracle-java8-installer

# Install Linux headers required for Nvidia driver installation
apt-get -y  install linux-headers-$(uname -r)

# Install Nvidia GTX1080 driver
./NVIDIA-Linux-x86_64-367.44.run -a -s

# Install CUDA 8.0 (followed by patch installation)
./cuda_8.0.27_linux.run  --toolkit --samples --samplespath=/usr/local/cuda-8.0/samples --override --silent
./cuda_8.0.27.1_linux.run --accept-eula --installdir=/usr/local/cuda --silent

# Install cuDNN 
tar -xf cudnn-8.0-linux-x64-v5.1.tgz -C /usr/local

# Install Python tools
apt-get -y  install python-numpy python-scipy python-matplotlib ipython ipython-notebook python-pandas python-sympy python-nose expect expect-dev
pip -q install --upgrade pip
pip -q install scikit-learn

# Install Bazel
echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
curl https://storage.googleapis.com/bazel-apt/doc/apt-key.pub.gpg | sudo apt-key add -
apt-get  update
apt-get -y  install bazel


########  With developer/user account (not root) in home directory :

# clone the Tensorflow source
git clone --branch v0.10.0rc0 https://github.com/tensorflow/tensorflow
cd tensorflow

# Configure Tensorflow
./configure

##########################################################################################
# Below, the answers to provide when being prompted by the configure script :
# Please specify the location of python. \[Default is /usr/bin/python\]: 
######-- ANSWER --> use default

# Do you wish to build TensorFlow with Google Cloud Platform support? \[y/N\] : 
######-- ANSWER -->  N 

# No Google Cloud Platform support will be enabled for TensorFlow Do you wish to build TensorFlow 
# with GPU support? \[y/N\]:
######-- ANSWER --> y

# Please specify which gcc should be used by nvcc as the host compiler. 
# [Default is /usr/bin/gcc\]: 
######-- ANSWER --> use default

# Please specify the Cuda SDK version you want to use, e.g. 7.0. \[Leave empty to use system default\]: 
######-- ANSWER --> use default

# Please specify the location where CUDA  toolkit is installed. R \[Default is /usr/local/cuda\]: 
######-- ANSWER --> use default

# Please specify the Cudnn version you want to use. \[Leave empty to use system default\]: 
######-- ANSWER --> use default

# Please specify the location where cuDNN  library is installed.  \[Default is /usr/local/cuda\]: 
######-- ANSWER --> use default

# Please specify a list of comma-separated Cuda compute capabilities you want to build with. 
# [Default is: \"3.5,5.2\"\]: 
######-- ANSWER --> 6.1

##########################################################################################

# Need to include link to CUDA directory in CROSSTOOL file (Don't forget to replace [user] by the user's home directory)
FILE_TO_PATCH="/home/[user]/tensorflow/third_party/gpus/crosstool/CROSSTOOL"
awk '/cxx_builtin_include_directory: \"\/usr\/include/ { print ; print "  cxx_builtin_include_directory: \"\/usr\/local\/cuda-8.0\/include\" " ;next }1' $FILE_TO_PATCH 2>/dev/null 1>./patched
cp ./patched $FILE_TO_PATCH
rm ./patched


# Build and Install Tensorflow
bazel build --logging 0 -c opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
sudo pip install --upgrade /tmp/tensorflow_pkg/tensorflow*.whl
sudo pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/protobuf-3.0.0b2.post2-cp27-none-linux_x86_64.whl



```

## Improve security with Let's Encrypt SSL certificates

As pre-requisite, you  have to own/get a valid domain name  at your hosting provider or other DNS provider (let's call it 'YOUR_DOMAIN.COM'). Depending on the domain extension you will choose, it can cost more or less, starting at a couple of Euros/Dollars)

Then you will have to associate your domain with the IP address of your server (With OVH hosting, it is quite easy and straight forward thanks to the OVH Manager). Whatever your solution, you have to 

  - add domain YOUR_DOMAIN.COM to a server (IPv4 - A) with target IP_OF_YOUR_SERVER         
  - add domain  rstudio.YOUR_DOMAIN.COM to a domain CNAME with target YOUR_DOMAIN.COM     # Sub-domain to reach R Studio Server 
  - add domain  hdfs.YOUR_DOMAIN.COM to a domain CNAME with target YOUR_DOMAIN.COM        # Sub-domain to reach Hadoop HDFS Admin page
  - add domain  cluster.YOUR_DOMAIN.COM to a domain CNAME with target YOUR_DOMAIN.COM     # Sub-domain to reach Hadoop Ressource Manager 
# add domain  jobs.YOUR_DOMAIN.COM to a domain CNAME with target YOUR_DOMAIN.COM         # Sub-domain to reach Spark Jobs Admin page (When Spark running) 

(You migh thave to wait 24/48H that DNS get updated over the internet to reflect these changes) 

After this, you can install and use Let's Encrypt to get some free SSL certificates for these domains. 

When used with the option *--letsencrypt*, the *setup-server.sh* script will install certbot (see https://certbot.eff.org ) and generate Let's Encrypt SSL standalone certificates for you for the following (sub)domains :
  - YOUR_DOMAIN.COM
  - rstudio.YOUR_DOMAIN.COM (if you are installing R Studio server with the option *--rserver*)
  - hdfs.YOUR_DOMAIN.COM (if you are installing Hadoop/Spark with the option *--hadoop*)
  - cluster.YOUR_DOMAIN.COM (if you are installing Hadoop/Spark with the option *--hadoop*)
  - jobs.YOUR_DOMAIN.COM (if you are installing Hadoop/Spark with the option *--hadoop*)

**Important** In order to register these certificates, the *setup-server.sh* script will prompt you for your domain name and contact email address : make sure the information provided are valid otherwise cerbot and the installation script will fail. 
(Note : the script only test for empty input. There is not (yet) a regex to verify for valid domain name or valid email address format)

Let's Encrypt is installed in the root home directory (/root/certbot-auto/). *cerbaut-auto* will install its stuff in /root/.local/share/letsencrypt/ .Let's Encrypt certificates are located in /etc/letsencrypt/

Finally, the installation script will add a crontab (user root) to renew the Let's encrypt certificates. You might want to adjust this crontab configuration : 

``` shell
~/Datascience-Sandbox-Installation# crontab -l
0 12 10 JAN,MAR,MAY,JUL,SEP,NOV * /root/certbot-auto/certbot-auto renew
```

## Usage : how to start/stop Hadoop/Spark mono cluster (if installed)

If you have installed Hadoop/Spark in your Sandbox, you can start / stop  the mono-cluster using the following 2 command/functions (defined in the .bashrc file) :
  - *hd-start*
  - *hd-stop*

Note :
  - *hd-start* will call another function *fw-allow* to try to "open" the firewall  (See Firewall section for details)
  - BUT in contrary *hd-stop* will not try to close the firewall as other programs like rstudio might still need to be accessed via port 443. You have to close "the" firewall manually 

Quicklinks to access the Hadoop/Spark admin pages (using Firefox on the server through x2goclient)
   * HDFS Admin : http://localhost:50070/
   * Yarn Admin : http://localhost:8088/cluster
   * Spark Admin (when spark is running) :http://localhost:4040/jobs/
   
(If you own a domain name, have installed some Let's Encrypt SSL certificates, and have opened the firewall, you will be able to access this admin pages via your browser over the internet)

## Important note about the firewall

By default the firewall will be enabled by the installation script via  *ufw*. Only Port 22 will be enabled

The installation script will prompt you to disable ssh connection for user root :
  - This is better for security when using a server in the cloud
  - However, this require to have defined a valid user ID with sudo privilege in order to be able to connect to the server via SSH. The installation script will create such user (by default, the script will use user name *hduser* and group *hadoop*  as defined in variable at the begining of the *setup-server.sh* script
  - If you wish to reverse this option, have a look at *PermitRootLogin* option in */etc/ssh/sshd_config* file
   

When generating SSL certificates with Let's Encrypt, cerbot requires port 443 to be open to validate some challenges. The installation script will open/close port 443 for this task to be performed.

When installing Let's Encrypt, the installation script will install nginx to translate (proxy) the local address/ports of hadoop/spark admin pages and R studio to the subdomains described in the Let's Encrypot section.

The *setup-server.sh* installation script will call the *gener_nginx_conf.sh* (in install subdirectory of this git project) to generate a very basic nginx configuration file using the domain name you have provided for Let's Encrypt. You might want to adjust this nginx connfiguration to suit your needs/requirements. The installation script save this nginx configuration in */etc/nginx/sites-enabled/nginx_conf*

After installing the nginx server, the script will try to determine your public IP adress you are using to connect to the server (try to find the first IP address that has succeeded to connect to the server via ssh as root), and then it will open the firewall only for *this IP* adress on port 80 and 443. As always, verify and adjust if needed the firewall configuration

``` shell
# Find the IP address of the remote SSH connecction to open the firewall just to us
# (The first IP address that has succeeded to connect to this server via ssh as root )
ip=$(sudo grep -e "^.*Accepted.*$(whoami).* ssh2$" /var/log/auth.log  | head -1 | cut -d" " -f11)
echo "Opening the firewall on port 80 and 443 for your remote IP address $ip"
ufw allow proto tcp from $ip to any port 80
ufw allow proto tcp from $ip to any port 443
ufw reload
ufw status
```

Similarly, in *.bashrc*, some command/functions are provided to open/close the firewall for your supposed public IP address. **Use with caution and always verify the firewall configuration with *sudo ufw status* ** (As this command is expected to be executed by a different user from root, this function looks for the last successful SSH connection of this user login id in order to find the public ip address to allow to pass through the fireall.

``` shell
function fw-allow {
	# Find the IP address of the remote SSH connecction to open the firewall
	ip=$(sudo grep -e "^.*Accepted.*$(whoami).* ssh2$" /var/log/auth.log  | tail -1 | cut -d" " -f11)
	echo "Opening the firewall on port 80 and 443 for your remote IP address $ip"
	sudo ufw allow proto tcp from $ip to any port 80
	sudo ufw allow proto tcp from $ip to any port 443
	sudo ufw reload
	sudo ufw status
  FIREWALL_PUPLIC_IP_ALLOWED=$ip
  export FIREWALL_PUPLIC_IP_ALLOWED
}

function fw-delete {
  if [ -z $FIREWALL_PUPLIC_IP_ALLOWED ] 
  then
	    # is there a known IP address that has opened the firewall ? If so, use it to close the firewall
      echo "Trying to close the firewall on port 80 and 443 for your remote IP address $FIREWALL_PUPLIC_IP_ALLOWED"
		  sudo ufw delete allow proto tcp from $FIREWALL_PUPLIC_IP_ALLOWED to any port 80
      sudo ufw delete allow proto tcp from $FIREWALL_PUPLIC_IP_ALLOWED to any port 443
 		  set -u $FIREWALL_PUPLIC_IP_ALLOWED
	else
      # Find the IP address of my remote SSH connecction to try to close the firewall    	
		  ip=$(sudo grep -e "^.*Accepted.*$(whoami).* ssh2$" /var/log/auth.log  | tail -1 | cut -d" " -f11)
		  echo "Closing the firewall on port 80 and 443 for your remote IP address $ip"
      sudo ufw delete allow proto tcp from $ip to any port 80
      sudo ufw delete allow proto tcp from $ip to any port 443
	fi
  sudo ufw reload
  sudo ufw status
}

```




## Things to improve
   * check Nvidia installers checksum in the installation script 
   * replace release candidate versions of Nvidia softwares by stable versions when available
   * Tensorflow installation : improve CROSSTOOL patch to include path to CUDA directory 
   * Possibility to have a post install script to be used in OVH manager when setting up the server ?
   * redirect some install display output to some logs file and have the instalaltion a bit more cleaner at display  
   * add a menu to select what sofwares to install. Improve installatio nscript arguments 
   * Make a VM or Docker image ? (at least without Nvidia software / License for public version ?)
   * ...

There are certainly lots of room for improvements in this installation script (My goal was not to have the perfect script but have a simple way to quickly setup a sandbox server for my needs)


