#!/bin/bash
set -e
clear 

echo "*******************************************************************"
echo "*                 DataScience Sandbox Installation                *"
echo "*                                                                 *"
echo "* v1.0 - Sept 2016                                                *"
echo "* https://github.com/fdasilva59/Datascience-Sandbox-Installation  *"
echo "*******************************************************************"
echo

if [[ $EUID -ne 0 ]]
then    
    echo "This script must be run as root" 1>&2
    exit 1
fi


##########################################################################
#################### Location of configuration files #####################
##########################################################################

# Location of configurations files to import
ressources="/root/Datascience-Sandbox-Installation/install"

# Define user login and group to create  
user_login="hduser"
user_group="hadoop"

# Hadoop file, version, url and signature
VERSION_Hadoop="hadoop-2.7.3"
ARCHIVE_Hadoop="hadoop-2.7.3.tar.gz"
SHA256_Hadoop="D489DF3808244B906EB38F4D081BA49E50C4603DB03EFD5E594A1E98B09259C2"
URL_Hadoop="http://dist.apache.org/repos/dist/release/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz"

# Spark file, version, url and signature
VERSION_Spark="spark-2.0.0-bin-hadoop2.7"
ARCHIVE_Spark="spark-2.0.0-bin-hadoop2.7.tgz"
URL_Spark="http://apache.mirrors.ovh.net/ftp.apache.org/dist/spark/spark-2.0.0/spark-2.0.0-bin-hadoop2.7.tgz"
MD5_Spark="3A1598EB7C32384830C48C779141C1C6"

# NVIDIA drivers
DRIVERS_INSTALL="NVIDIA-Linux-x86_64-367.44.run"
NVIDIA_VERSION="367.44"
CUDA_INSTALL="cuda_8.0.27_linux.run"
CUDA_PATCH="cuda_8.0.27.1_linux.run"
CUDNN_INSTALL="cudnn-8.0-linux-x64-v5.1.tgz"

# TensorFlow version (tag)
TF_TAG="v0.10.0rc0"


# RStudio
RSTUDIO_FILE="rstudio-0.99.903-amd64-debian.tar.gz"
RSTUDIO_URL="https://download1.rstudio.org/rstudio-0.99.903-amd64-debian.tar.gz"
RSTUDIO_DIR="rstudio-0.99.903"


# default script parameters
TF=true
TORCH=true
CUDA=true
HADOOP=true
R=true
CONDA=false

#### HACK FOR DEBUG
# BEGIN DEBUG (Put just before begining of a portion of codecto skip)
#if false; then
# END DEBUG (Put just after a portion of code to skip)
# fi


# Check script parameters
while [ $# -gt 0 ]
do
   case "$1" in
      --notensorflow) echo "Skip TensorFlow installation" 
                      TF=false
                      ;;
      --nocudagpu)    echo "CUDA GPU support disabled in TensorFlow"  
                      CUDA=false
                      ;;
      --notorch)      echo "Skip Torch installation"
                      TORCH=false
                      ;;
      --nohadoop)     echo "Skip Hadoop/Spark installation" 
                      HADOOP=false
                      ;;
      --nor)          echo "Skip R and RStudio installation"
                      R=false
                      ;;
      --conda)        echo "Install miniconda"
                      CONDA=true
                      ;;
      --help)         echo "

This script allows to quickly confifure a server ipreloaded with a fresh Ubuntu 14.04LTS
to experiment with DataScience softwares. By default, the full installation will install 
the latest release of TensorFlow (with CUDA GPU support), Torch, R and RSTudio, and finally 
a Hadoop/Yarn/Spark 'mono cluster'. (It will also install required dependencies and tools) 

RStudio is intended to be used through a x2go client from a remote computer
                            
You can use the following installation parameters : 
     
    --notensorflow    to skip TensorFlow installation
  
    --nocudagpu       to disable CUDA GPU support in TensorFlow 
                      (note : you will also have to disable cuda when prompted by the configure
                       script use to build TensorFlow)

    --notorch         to skip Torch installation 

    --nohadoop        to skip Hadoop/Yarn/Spark installation

    --nor             to skip R and Rstudio installation

    --conda           to install miniconda with numpy, scipy, sci-kit learn

    --help            to display this help menu  

"
                      exit
                      ;;
    esac
    shift
done


echo
read -p "Continue ? [Y/n] " yn
case $yn in
   [Yy]* ) echo "Starting installation";;
       * ) echo "Aborting Installation." ; exit ;;
esac


echo
echo "***********************************************"
echo "*****   Step 0 : Restaure Env for root   ******"
echo "***********************************************"
echo
chown -R root:root $ressources
cp -f $ressources/.bashrc /root/.bashrc
cp -f $ressources/.profile /root/.profile
source /root/.profile
source /root/.bashrc


echo
echo "*******************************************"
echo "*****   Step 1 : configure firewall   *****"
echo "*******************************************"
echo
ufw enable
ufw allow ssh
ufw reload
ufw status numbered

echo
echo "*******************************************"
echo "*****     Step 2 : update ubuntu      *****"
echo "*******************************************"
echo "Note : Update can take a while..."
echo
apt-get -y -q=2 install software-properties-common
add-apt-repository -y universe
apt-add-repository -y multiverse
add-apt-repository -y ppa:x2go/stable
add-apt-repository -y ppa:webupd8team/java
apt-get -q=2 update
apt-get -y -q=2 upgrade

echo
echo "****************************************************************************"
echo "***** Step 3 : create user $user_login and grant superuser privileges       "
echo "****************************************************************************"
echo
set +e
egrep -i "$user_group" /etc/group 2>&1 > /dev/null 
if [ $? -eq 0 ] 
then 
     echo "group $user_group already exist : no change" 
else 
     addgroup $user_group
fi
egrep -i "$user_login" /etc/passwd 2>&1 > /dev/null
if [ $? -eq 0 ]  
then 
     echo "user $user_login already exist : no change" 
else      
     adduser --quiet --ingroup $user_group $user_login
     usermod -a -G sudo $user_login
fi
set -e

echo
echo "*********************************************"
echo "***** Step 4 : ssh conf for user $user_login "
echo "*********************************************"
echo
if [ -d /home/$user_login/.ssh ]
then 
     echo "ssh directory already exist for $user_login : no change"
elif [ -f $ressources/perso/ssh.tar ]
then 
     echo "Found local archive of ssh credentials to restaure"
     mkdir /home/$user_login/.ssh
     cp $ressources/perso/ssh.tar /home/$user_login/.ssh
     cd /home/$user_login/.ssh
     tar xvf ssh.tar
     chown -R $user_login:$user_group /home/$user_login/.ssh
     chmod 600 /home/$user_login/.ssh/authorized_keys2
     rm ssh.tar
     cd /root
else
     echo "ssh keys created for user $user_login "
     su - $user_login -c "ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa"
     su - $user_login -c "cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys2"
     su - $user_login -c "chmod 600 ~/.ssh/authorized_keys2"
fi

echo
echo "*******************************************"
echo "*****     Step 5 : install x2go       *****"
echo "*******************************************"
echo
apt-get -y -q=2 install x2goserver x2goserver-xsession
echo
echo "You can download a x2go client here : http://wiki.x2go.org/doku.php/download:start#x2go_client "
echo

echo "*******************************************"
echo "*****     Step 6 : install Java8      *****"
echo "*******************************************"
echo
apt-get -y -q=2 install oracle-java8-installer



if ($HADOOP) then
	echo "*******************************************"
	echo "*****     Step 7 : install Hadoop     *****"
	echo "*******************************************"
        echo
	if [ -d /usr/local/$VERSION_Hadoop ]
	then
	     echo " $VERSION_Hadoop already installed : no change"
	else
	     echo "Downloading $VERSION_Hadoop"
	     wget -nv $URL_Hadoop
	     sig="$(shasum -a256 hadoop-2.7.3.tar.gz | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]' )"      
	     if [ $sig = $SHA256_Hadoop ]
	     then echo "$VERSION_Hadoop : checksum OK" 
	     else 
		  echo "ERROR : $VERSION_Hadoop checksum does not match"
		  exit
	     fi	
	     tar -xf $ARCHIVE_Hadoop
	     mv $VERSION_Hadoop/ /usr/local/$VERSION_Hadoop/
	     rm -f /usr/local/hadoop
	     ln -s /usr/local/$VERSION_Hadoop /usr/local/hadoop
	     chown -R $user_login:$user_group /usr/local/hadoop
	     chown -R $user_login:$user_group /usr/local/$VERSION_Hadoop
	     rm $ARCHIVE_Hadoop
	fi


	echo
	echo "*******************************************"
	echo "*****     Step 8 : install Spark      *****"
	echo "*******************************************"
	echo
        if [ -d /usr/local/$VERSION_Spark ]
	then 
	     echo "$VERSION_Spark already installed : no change"
	else
	     echo "Downloading $VERSION_Spark"
	     wget -nv $URL_Spark
	     sig="$(md5sum $ARCHIVE_Spark | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]' )"
	     if [ $sig = $MD5_Spark ]
	     then echo "$VERSION_Spark : checksum OK" 
	     else
          echo "ERROR : $VERSION_Spark checksum does not match"
          exit
	     fi
	     tar -xf $ARCHIVE_Spark
	     mv $VERSION_Spark/ /usr/local/$VERSION_Spark/
	     rm -f /usr/local/spark 
	     ln -s /usr/local/$VERSION_Spark /usr/local/spark
	     chown -R $user_login:$user_group /usr/local/$VERSION_Spark
	     rm $ARCHIVE_Spark
	fi

else
   echo "*******************************************"
   echo "*****  SKIP Step 7 : install Hadoop   *****"
   echo "*******************************************"
   echo
   echo "*******************************************"
   echo "*****  SKIP Step 8 : install Spark    *****"
   echo "*******************************************"
   echo
fi


echo
echo "**************************************************************"
echo "*****  Step 9 : configure Home Env (inc Hadoop and Spark)  ***"
echo "**************************************************************"
echo
cp -f $ressources/.bashrc /home/$user_login/.bashrc
chown $user_login:$user_group /home/$user_login/.bashrc
cp -f $ressources/.profile /home/$user_login/.profile
chown $user_login:$user_group /home/$user_login/.profile
read -p "Do you wish to block SSH access connections for Root user ? (Warning : You must use another valid user login ID to connect to the server via SSH and make sure the port 22 on the Firewall is always enabled ) : [yes/NO] " yn
             case $yn in
                     yes ) echo "Disabling SSH root access" ; cp -f $ressources/sshd_config /etc/ssh/sshd_config ;;
                       * ) echo "SSH configuration : no change"  ;;
             esac
echo

if [ -L /usr/local/java ]
then
     echo "Link /usr/local/java already exists : no change"
else
     ln -s /usr/lib/jvm/java-8-oracle/jre /usr/local/java
     chown  $user_login:$user_group /usr/local/java
fi

# Create home directory for python development
if [ -d /home/$user_login/develop ]
then    
     echo "/home/$user_login/develop already exists : no change" 
else    
     mkdir /home/$user_login/develop
     chown $user_login:$user_group /home/$user_login/develop
fi 



if ($HADOOP) then
        echo
        echo "Configuring Hadoop/Yarn/Spark as a Mono-Cluster sandbox"
        echo

	# Spark configuration (Standalone Cluster Install with Hadoop, YARN, Hive metastore without Hive)
	cp -f $ressources/hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh
	chown $user_login:$user_group /usr/local/hadoop/etc/hadoop/hadoop-env.sh
	chmod u+x /usr/local/hadoop/etc/hadoop/hadoop-env.sh

	cp -f $ressources/core-site.xml /usr/local/hadoop/etc/hadoop/core-site.xml 
	chown $user_login:$user_group /usr/local/hadoop/etc/hadoop/core-site.xml  

	cp -f $ressources/hdfs-site.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml 
	chown $user_login:$user_group /usr/local/hadoop/etc/hadoop/hdfs-site.xml  

	cp -f $ressources/mapred-site.xml /usr/local/hadoop/etc/hadoop/mapred-site.xml
	chown $user_login:$user_group /usr/local/hadoop/etc/hadoop/mapred-site.xml

	cp -f $ressources/yarn-env.sh /usr/local/hadoop/etc/hadoop/yarn-env.sh
	chown $user_login:$user_group /usr/local/hadoop/etc/hadoop/yarn-env.sh
	chmod u+x /usr/local/hadoop/etc/hadoop/yarn-env.sh

	cp -f $ressources/yarn-site.xml /usr/local/hadoop/etc/hadoop/yarn-site.xml
	chown $user_login:$user_group /usr/local/hadoop/etc/hadoop/yarn-site.xml

	cp -f $ressources/mapred-env.sh /usr/local/hadoop/etc/hadoop/mapred-env.sh
	chown $user_login:$user_group /usr/local/hadoop/etc/hadoop/mapred-env.sh
	chmod u+x /usr/local/hadoop/etc/hadoop/mapred-env.sh

	cp -f $ressources/hive-site.xml /usr/local/hadoop/etc/hadoop/hive-site.xml
	chown $user_login:$user_group /usr/local/hadoop/etc/hadoop/hive-site.xml


	# Create Root directory for HDFS and Hive storage
	if [ -d /data ]
	then 
	     echo "HDFS data home already exist : no change"
	else
	     mkdir /data
	     mkdir /data/hive-metastore-db
	     chmod -R 750 /data 
	     chown -R $user_login:$user_group /data
             su - $user_login -c "/usr/local/hadoop/bin/hdfs namenode -format"
	fi

fi


if ($R) then
	echo
	echo "***********************************************"
	echo "*****  Step 10 : install R  and R Studio  *****"
	echo "***********************************************"
	echo
	if [ -d /usr/local/$RSTUDIO_DIR ]
	then
	     echo "RStudio already installed : no change."
	else
	     # libgstreamer is used by rstudio
             apt-get -yq install r-base libgstreamer0.10-0 libgstreamer-plugins-base0.10-dev 
	     wget $RSTUDIO_URL
	     tar xf $RSTUDIO_FILE
             mv $RSTUDIO_DIR /usr/local/$RSTUDIO_DIR
	     ln -s /usr/local/$RSTUDIO_DIR /usr/local/rstudio
	     chown -R $user_login:$user_group /usr/local/rstudio
	     rm $RSTUDIO_FILE
	fi
else
        echo
        echo "******************************************************"
        echo "***** SKIP :  Step 10 : install R  and R Studio  *****"
        echo "******************************************************"
        echo

fi


echo
echo "*******************************************"
echo "*****  Step 11 : install Dev tools    *****"
echo "*******************************************"
echo
apt-get -y -q=2 install git zip unzip autoconf automake cmake libtool curl zlib1g-dev  g++ vim aptitude arp-scan swig python-pip python-dev firefox


if ($CONDA) then
	echo
	echo "******************************************************"
	echo "*****  Step 12 : install anaconda, numpy, scikit *****"
	echo "******************************************************"
	echo
	if [ -d /home/$user_login/miniconda ]
	then 
	     echo "miniconda already installed"
	else
	     su - $user_login -c "cd /home/$user_login ; wget http://repo.continuum.io/miniconda/Miniconda3-3.7.0-Linux-x86_64.sh -O ./miniconda.sh"
	     su - $user_login -c "cd /home/$user_login ; bash ./miniconda.sh -b -p /home/$user_login/miniconda"
	     su - $user_login -c "cd /home/$user_login ; miniconda/bin/conda install numpy scikit-learn scipy"
	     su - $user_login -c "cd /home/$user_login ; miniconda/bin/conda create -n deeppy numpy scikit-learn scipy"
	     rm /home/$user_login/miniconda.sh
	fi
else
        echo
        echo "********************************************************"
        echo "*** SKIP Step 12 : install anaconda, numpy, scikit *****"
        echo "********************************************************"
        echo
fi


if ($CUDA ) then
	echo
	echo "**************************************************************"
	echo "*****  Step 13 : Install NVIDIA Pascal GTX1080 drivers   *****"
	echo "**************************************************************"
        echo

        # See : http://www.nvidia.com/object/gpu-accelerated-applications-tensorflow-installation.html

        # Check if Nvidia drivers are already installed
        skip_nvidia=false
        if [ -f /usr/bin/nvidia-smi ]
        then
		nvidia-smi > test-nvidia
		NVIDIA_INSTALLED_VERSION=$(grep "NVIDIA-SMI" test-nvidia | cut -d':' -f2 | cut -d'|' -f1 | sed 's/ //g') 
		rm test-nvidia
		if [ "$NVIDIA_INSTALLED_VERSION" == "$NVIDIA_VERSION" ]
		then
			echo "NVIDIA-SMI $NVIDIA_INSTALLED_VERSION is already installed. Skip NVIDIA drivers installation"
		        skip_nvidia=true
                else
			echo "Another Nvidia drivers is already installed : NVIDIA-SMI $NVIDIA_INSTALLED_VERSION. Skip NVIDIA drivers installation."
			read -p "Do you wish to continue the server installation [Y/N] " yn
			case $yn in
				[Yy]* ) echo ""; skip_nvidia=false ;;
				 * ) echo "Aborting Installation." ; exit ;;
			esac
		fi
        fi
        
        if !($skip_nvidia) then       
		# Before installing Nvidia Drivers, check if  NVIDIA installer is present
		if [ -f $ressources/nvidia/$DRIVERS_INSTALL ] 
		then 
		     echo "Found local version of $DRIVERS_INSTALL"
		     apt-get -y -q=2 install linux-headers-$(uname -r)
		     $ressources/nvidia/NVIDIA-Linux-x86_64-367.44.run -a -s
		else
		     echo
                     echo "Cannot find $ressources/nvidia/$DRIVERS_INSTALL"
		     echo "Please, visit http://www.nvidia.com/drivers to download the drivers for the Graphics card"
		     echo "Aborting installation"
		     exit
		fi
         fi

else
        echo
        echo "*****************************************************************"
        echo "*** SKIP Step 13 : Install NVIDIA Pascal GTX1080 drivers    *****"  
        echo "*****************************************************************"
        echo
fi


if ($CUDA ) then
        echo
        echo "**************************************************"
        echo "*****  Step 14 : NVIDIA GPU : Install CUDA   *****"
        echo "**************************************************"
        echo

        if [ -f $ressources/nvidia/$CUDA_INSTALL ] 
        then 
             echo "Found local version of $CUDA_INSTALL"
              $ressources/nvidia/$CUDA_INSTALL  --toolkit --samples --samplespath=/usr/local/cuda-8.0/samples --override --silent
        else
             echo "Cannot find $ressources/nvidia/$CUDA_INSTALL"
             echo "Please, visit https://developer.nvidia.com/cuda-release-candidate-download to download CUDA for Pascal architecture"
             echo "Aborting installation"
             exit
        fi

        if [ -f $ressources/nvidia/$CUDA_PATCH ]    
        then 
             echo "Found local version of $CUDA_PATCH"
             $ressources/nvidia/$CUDA_PATCH --accept-eula --installdir=/usr/local/cuda --silent
        else
             echo
             echo "Cannot find $ressources/nvidia/$CUDA_PATCH"
             echo "Please, visit https://developer.nvidia.com/cuda-release-candidate-download to download CUDA for Pascal architecture"
             read -p "Do you wish to continue the server installation [Y/N] " yn
             case $yn in
                   [Yy]* ) echo "" ;;
                       * ) echo "Aborting Installation." ; exit ;;
             esac
        fi

else
        echo
        echo "******************************************************"
        echo "***** SKIP Step 14 : NVIDIA GPU : Install CUDA   *****"
        echo "******************************************************"
        echo
fi



if ($CUDA ) 
then
	echo
	echo "**************************************************"
	echo "*****  Step 15 : NVIDIA GPU : Install cuDNN  *****"
	echo "**************************************************"
	echo

        if [ -f $ressources/nvidia/$CUDNN_INSTALL ]
        then
             echo "Found local version of $CUDNN_INSTALL "
	     tar -xf $ressources/nvidia/$CUDNN_INSTALL -C /usr/local
        else
             echo
             echo "Cannot find $ressources/nvidia/$CUDNN_INSTALL"
             echo "Please, visit https://developer.nvidia.com/cudnn to download CUDNN"
             echo "Aborting installation"
             exit
        fi
else
        echo
        echo "**************************************************"
        echo "*** SKIP  Step 15 : Nvidia GPU : Install cuDNN ***"
        echo "**************************************************"
        echo
fi

if ($TF)
then
	echo
	echo "*************************************************************************************"
	echo "*****  Step 16 : Prepare TensorFlow Installation : Install Python, Numpy, ...   *****"
	echo "*************************************************************************************"
        echo
        apt-get -y -q=2 install python-numpy python-scipy python-matplotlib ipython ipython-notebook python-pandas python-sympy python-nose expect expect-dev
	pip -q install --upgrade pip 
        pip -q install scikit-learn

	echo
	echo "***********************************************************************"
	echo "*****  Step 17 : Prepare TensorFlow Installation : Install Bazel  *****"
	echo "***********************************************************************"
        echo
	echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list 
	curl https://storage.googleapis.com/bazel-apt/doc/apt-key.pub.gpg | sudo apt-key add - 
	apt-get -q=2 update 
	apt-get -y -q=2 install bazel 

	echo
	echo "*************************************************************"
	echo "*****     Step 18 : Build and Install TensorFlow        *****"
	echo "*************************************************************"
	echo
	echo "Note : When you will be prompted by the configure script, choose the DEFAULT values"
	# echo "Note : When you will be prompted by the configure script, choose the DEFAULT values except for the GPU support which needs to be enabled"
	echo
	if [ -d /home/$user_login/tensorflow ]
	then
	     rm -rf /home/$user_login/tensorflow
	fi
        su - $user_login -c "git clone --branch $TF_TAG https://github.com/tensorflow/tensorflow "
        #if ($CUDA = true) then 
            #echo
            #echo " IMPORTANT :"
            #echo "When prompted by the configure script to build TensorFlow, dont't forget to answer YES to the question about GPU support"
	    #read -p "Press a key to continue " yn
        #fi
        #su - $user_login -c "cd /home/$user_login/tensorflow; ./configure" 
        
	if !($CUDA ) 
        then

              echo "Configure Tensorflow (no GPU support)"
              cp $ressources/conf_tf /home/$user_login/tensorflow/conf_tf
              chown $user_login:$user_group /home/$user_login/tensorflow/conf_tf
              su - $user_login -c "cd /home/$user_login/tensorflow ; ./conf_tf"
              echo "Build TensorFlow (no GPU support)" 
              su - $user_login -c "cd /home/$user_login/tensorflow ; bazel build --logging 0 -c opt //tensorflow/tools/pip_package:build_pip_package"
              rm /home/$user_login/tensorflow/conf_tf

        else
              echo "Configure Tensorflow with CUDA / Pascal GPU support"
              cp $ressources/conf_tf_cuda /home/$user_login/tensorflow/conf_tf_cuda
              chown $user_login:$user_group /home/$user_login/tensorflow/conf_tf_cuda
              su - $user_login -c "cd /home/$user_login/tensorflow ; ./conf_tf_cuda" 
              echo "Build TensorFlow with CUDA GPU support" 

              echo 
              FILE_TO_PATCH="/home/$user_login/tensorflow/third_party/gpus/crosstool/CROSSTOOL"
              echo "Need to patch $FILE_TO_PATCH for missing dependency declarations with Bazel : /usr/local/cuda-8.0/include/" 
              echo "see: https://github.com/tensorflow/tensorflow/issues/3431#issuecomment-234131699 "
              awk '/cxx_builtin_include_directory: \"\/usr\/include/ { print ; print "  cxx_builtin_include_directory: \"\/usr\/local\/cuda-8.0\/include\" " ;next }1' $FILE_TO_PATCH 2>/dev/null 1>./patched
              cp ./patched $FILE_TO_PATCH
              rm ./patched
              su - $user_login -c "cd /home/$user_login/tensorflow ; bazel build --logging 0 -c opt --config=cuda //tensorflow/tools/pip_package:build_pip_package" 
	fi
	su - $user_login -c "cd /home/$user_login/tensorflow ; bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg" 
	pip install --upgrade /tmp/tensorflow_pkg/tensorflow*.whl	 
	pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/protobuf-3.0.0b2.post2-cp27-none-linux_x86_64.whl 
        echo "Tensorflow installation is finished !"
else
        echo
        echo "***********************************************************************"
        echo "*** SKIP Step 16 : Prepare TensorFlow Installation : Install python ***"
        echo "***********************************************************************"
        echo
        echo "***********************************************************************"
        echo "*** SKIP Step 17 : Prepare TensorFlow Installation : Install Bazel  ***"
        echo "***********************************************************************"
        echo
        echo "*************************************************************"
        echo "*** SKIP  Step 18 : Build and Install TensorFlow        *****"
        echo "*************************************************************"
        echo
fi

if ($TORCH )
then
	echo
	echo "*************************************************************"
	echo "*****         Step 19 :  Build and Install Torch        *****"
	echo "*************************************************************"
        echo
	if [ -d /home/$user_login/torch ]
	then
	     rm -rf /home/$user_login/torch
	fi
	su - $user_login -c "cd /home/$user_login ; git clone https://github.com/torch/distro.git ./torch --recursive "
	cd /home/$user_login/torch 
	./install-deps
	cd
	su - $user_login -c "cd /home/$user_login/torch ; ./install.sh -b -s"
else
        echo
        echo "*************************************************************"
        echo "*****    SKIP Step 19 :  Build and Install Torch        *****"
        echo "*************************************************************"
        echo
fi


# Reboot the system
echo
echo "*************************************************************"
echo "*****           Server Installation finished !         *****"
echo "*************************************************************"
echo
echo  "Press a key to reboot the system"
read -p "Reboot the system NOW ? [Y/n] " yn
case $yn in
   [Yy]* ) echo "Going for reboot..." ; reboot ;;
       * ) exit ;;
esac

