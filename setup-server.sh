#!/bin/bash
set -e
clear 

echo "*******************************************************************"
echo "*                 DataScience Sandbox Installation                *"
echo "*                                                                 *"
echo "* v1.1 - Sept 2016                                                *"
echo "* https://github.com/fdasilva59/Datascience-Sandbox-Installation  *"
echo "*******************************************************************"
echo

# Am I root ?
if [[ $EUID -ne 0 ]]
then    
    echo "This script must be run as root" 1>&2
    exit 1
fi


##########################################################################
####################      SETUP CONFIGURATION        #####################
##########################################################################

# Location of configurations files to import (By default it is expected you clone the installation git repository in the /root directory)
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
CRAN_MIRROR="https://mirror.ibcp.fr/pub/CRAN/bin/linux/ubuntu trusty/" 
RSTUDIO_FILE="rstudio-0.99.903-amd64-debian.tar.gz"
RSTUDIO_URL="https://download1.rstudio.org/rstudio-0.99.903-amd64-debian.tar.gz"
RSTUDIO_DIR="rstudio-0.99.903"
RSTUDIO_SERVER_FILE="rstudio-server-0.99.903-amd64.deb"
RSTUDIO_SERVER_URL="https://download2.rstudio.org/rstudio-server-0.99.903-amd64.deb"


# default script parameters
TF=false
CUDA=false
TORCH=false
HADOOP=false
LETS_ENCRYPT=false
R=false
R_STD_DESKTOP=false
R_STD_SERVER=false
CONDA=false



## USAGE --help description
HELP=$"This script allows to quickly configure a server (with Ubuntu 14.04LTS already preinstalled on it)
to experiment with DataScience softwares. The full installation will install the latest release of 
TensorFlow (with CUDA GPU support), Torch, R and R Studio, and finally a Hadoop/Yarn/Spark 'mono cluster'. 
(It will also install required dependencies and tools) 

R Studio Desktop (or  tools like Firefox) are intended to be used through a x2go client from a remote computer
                            
You can use the following installation parameters : 
     
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


Suggestion of configuration  : 

 * Deep Learning :  Tensorflow and Torch with Nvidia Cuda support, execute :

      ./setup-server.sh --cuda --tensorflow --torch


 * Big Data : R Studio Server, Hadoop/Spark (mono cluster/sandbox) :

      ./setup-server.sh  --hadoop --letsencrypt --rserver


 * Full Data Science Sandbox : 

      ./setup-server.sh --cuda --tensorflow --torch --hadoop --letsencrypt --rserver
  

"
 


# Check script parameters : if no parameters, display help
if  [ $# -eq 0 ]
then
     echo "$HELP" 
     exit
fi   

# Scripts arguments to pass the software list to install  
while [ $# -gt 0 ]
do
   case "$1" in
      --tensorflow) echo "Install TensorFlow" 
                      TF=true
                      ;;
      --cuda)         echo "CUDA GPU support ensabled for TensorFlow (and/or Torch)"  
                      CUDA=true
                      ;;
      --torch)        echo "Install Torch"
                      TORCH=true
                      ;;
      --hadoop)       echo "Install Hadoop/Spark" 
                      HADOOP=true
                      ;;
      --letsencrypt)  echo "Install and configure SSL on the server with Let's Encrypt"
                      LETS_ENCRYPT=true
                      ;;
      --rserver)      echo "Install R studio Server (It is strongly recommended to install/enable free Let's encrypt SSL certificates"
                      R_STD_SERVER=true
                      ;;
      --rdesktop)     echo "Install RStudio Desktop"
                      R_STD_DESKTOP=true  
                      ;;
      --conda)        echo "Install miniconda"
                      CONDA=true
                      ;;
      --help)         echo "$HELP"
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

if ((  ($HADOOP) || ($R_STD_SERVER) ) && !($LETS_ENCRYPT) ) 
then
     echo
     echo "IMPORTANT : "
     echo "It is highly recommended to enable SLL / install Let's Encrypt if you plan to use R Studio Server and/or Hadoop"
     echo " >>>> Let's Encrypt certificates are free, but you will need to provide a Domain Name (you already own) for your 
                 server in order to generate SSL certificates for the (sub)domains tomanage on this server"
     echo " >>>> If you have a tarball backup of your Let's encrypt certicates, make sure it is available in $ressources/perso/letsencrypt-bck.tar.gz"
     echo
     read -p "Enable let's Encrypt SSL ? [Y/n] " yn
     case $yn in
	   [nN]* ) echo "Continue installation WITHOUT SSL support"           
           ;;
           * ) echo "Good choice ! Continue installation WITH SSL support" ;;
     esac
fi




#### HACK FOR DEBUG
# BEGIN DEBUG (Put just before begining of a portion of codecto skip)
#if false; then 
# END DEBUG (Put just after a portion of code to skip)
# fi


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
# enable firewall and allow only SSH connection
yes | ufw enable
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
# Update to install R
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -
echo "# Add CRAN mirror" >> /etc/apt/sources.list
echo "deb $CRAN_MIRROR" >>/etc/apt/sources.list

apt-get -q=2 update
apt-get -y -q=2 upgrade

echo
echo "****************************************************************************"
echo "***** Step 3 : create user $user_login and grant superuser privileges       "
echo "****************************************************************************"
echo
# Check if user group already exist, in case of error create it
set +e 
egrep -i "$user_group" /etc/group 2>&1 > /dev/null 
if [ $? -eq 0 ] 
then 
     echo "group $user_group already exists : no change" 
else 
     addgroup $user_group
fi
# Check if user login already exist, in case of error create it
egrep -i "$user_login" /etc/passwd 2>&1 > /dev/null
if [ $? -eq 0 ]  
then 
     echo "user $user_login already exists : no change" 
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
     echo "Found local archive of ssh credentials to restore"
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

# Verify local ssh connection silently
su - $user_login -c "ssh -oStrictHostKeyChecking=no 127.0.0.1 uname -a" > /dev/null
su - $user_login -c "ssh -oStrictHostKeyChecking=no localhost uname -a" > /dev/null



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
	     if [ ! -d /usr/local/hadoop/logs ]
	     then
		  mkdir /usr/local/hadoop/logs	
                  chown $user_login:$user_group /usr/local/hadoop/logs
             fi
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


if ($R_STD_DESKTOP) then
	echo
	echo "*******************************************************"
	echo "*****  Step 10 : install R  and R Studio DESKTOP  *****"
	echo "*******************************************************"
	echo
	if [ -d /usr/local/$RSTUDIO_DIR ]
	then
	    echo "R Studio Desktop already installed : no change."
	else
	    # libgstreamer is used by rstudio, libcurl is required to install swirl in R Studio
            apt-get -y -q=2 install r-base libgstreamer0.10-0 libgstreamer-plugins-base0.10-dev libcurl4-openssl-dev
	    wget $RSTUDIO_URL
	    tar xf $RSTUDIO_FILE
            mv $RSTUDIO_DIR /usr/local/$RSTUDIO_DIR
	    ln -s /usr/local/$RSTUDIO_DIR /usr/local/rstudio
	    chown -R $user_login:$user_group /usr/local/rstudio
	    rm $RSTUDIO_FILE
	 fi
else
        echo
        echo "*************************************************************"
        echo "***** SKIP :  Step 10 : install R and R Studio Desktop *****" 
 	echo "*************************************************************"
        echo
fi

if ($R_STD_SERVER) then
        echo
        echo "*******************************************************"
        echo "*****  Step 11 : install R  and R Studio SERVER   *****"
        echo "*******************************************************"
        echo
        if [ -d /usr/lib/rstudio-server ]
        then
             echo "R Studio Server already installed : no change."
        else
                  apt-get -y -q=2 install r-base gdebi-core libcurl4-openssl-dev
                  wget $RSTUDIO_SERVER_URL
                  dpkg -i $RSTUDIO_SERVER_FILE
                  rm $RSTUDIO_SERVER_FILE
        fi
else
        echo
        echo "************************************************************"
        echo "***** SKIP :  Step 11 : install R  and R Studio SERVER *****"
        echo "************************************************************"
        echo
fi


if ($LETS_ENCRYPT) 
then
        echo
        echo "************************************************************"
        echo "***** Step 12 : Install Let's Encrypt SSL              *****"
        echo "************************************************************"
        echo

	# If some Let's Encrypt certificates appears to may exist we avoid to change/do anything 
	if [ -d /etc/letsencrypt/ ] 
	then
		echo "Let's encrypt certificates may already exists in /etc/letsencrypt/ : no change"
	else
                echo "Install Let's Encrypt"
        	# Download Let's Encrypt in no installer found from a previous execution of this script
                if [ -d /root/certbot-auto ] 
		then
			echo "Found previous installation of Let's Encrypt in /root/certbot-auto"
		else
			echo "Let's Encrypt will be installed in /root/certbot-auto"
			mkdir /root/certbot-auto
	                cd /root/certbot-auto
	                wget https://dl.eff.org/certbot-auto
	                chmod a+x certbot-auto
		fi	

		# If a personal backup of certifiactes is found, we skip certificates creation and we restore them	
                if [ -f $ressources/perso/letsencrypt-bck.tar.gz ]
		then
			echo "Found local backup version of Let's Encrypt certificates: restoring them"
			tar xf $ressources/perso/letsencrypt-bck.tar.gz -C /
		else

			# Open Firewall on port 443 to let pass Let's Encrypt installation challenges
                        ufw allow 443
                        ufw reload
                        ufw status

			# Create certificates (you need to own/provide a valid domain name)
			echo "Create Let's encrypt certificates for your domain name" 
			echo 
	                # Retrieve email address and domain name to be use for Let's encrypt registration	
			check=true
			while ($check)
			do
			   read -p "Enter the main domain name you own for this server (i.e. nvidia.com ) : " dn
			   if [ -z $dn ]
			   then
				echo "domain name cannot be empty"
				continue
			   fi

			   read -p "Email address for registration and recovery contact  : " email_address
			   if [ -z $email_address ]
			   then
				echo "email address cannot be empty"
				continue
			   fi

			   echo
			   echo "Are these information correct ?"
			   echo
			   echo "    Domain name : $dn"
			   echo "    Email address for registration and recovery contact : $email_address "
			   echo
			   read -p  "Are these information correct ? [y/n] " yn
                           echo
			   case $yn in
			   [Yy]* ) echo "Starting generating SSL certificates with Let's Encrypt" ;
				   check=false ;
				   ;;
			       * ) ;;
			   esac

			done
			echo
	
			echo "Trying to generate a Let's Encrypt SSL certificate for domain : $dn"
			/root/certbot-auto/certbot-auto certonly -d $dn --standalone  --noninteractive --agree-tos --email $email_address

			if ($R_STD_SERVER) then
				echo "Trying to generate a Let's Encrypt SSL certificate for rstudio sub-domain : rstudio.$dn"
				/root/certbot-auto/certbot-auto certonly -d rstudio.$dn --standalone  --noninteractive --agree-tos --email $email_address
			fi
			if ($HADOOP) then
				echo "Trying to generate a Let's Encrypt SSL certificate for sub-domains : hadoop.$dn cluster.$dn jobs.$dn" 
				/root/certbot-auto/certbot-auto certonly -d hdfs.$dn --standalone  --noninteractive --agree-tos --email $email_address
				/root/certbot-auto/certbot-auto certonly -d cluster.$dn --standalone  --noninteractive --agree-tos --email $email_address
				/root/certbot-auto/certbot-auto certonly -d jobs.$dn --standalone  --noninteractive --agree-tos --email $email_address
			fi
                       # Generate Nginx server conf for given domains
                        $ressources/gener_nginx_conf.sh $dn

                        # Backup the certificates created
                        if [ -d $ressources/perso ]
                        then
                                tar -cf $ressources/perso/letsencrypt-bck.tar /etc/letsencrypt /etc/nginx/sites-enabled/nginx_conf
                                gzip $ressources/perso/letsencrypt-bck.tar
				echo
				echo "A zip Tarball backup of the created Let's Encrypt Certificates has been stored in $ressources/perso/letsencrypt-bck.tar : DON'T FORGET TO SAVE IT IN A SECURE PLACE (other server)" 
                        fi


		fi
	
			# Crontab to renew the Let's encrypt certificates
 			echo "Installing crontab to renew Let's Encrypt certificates"
			cat <(crontab -l) <(echo "0 12 10 JAN,MAR,MAY,JUL,SEP,NOV * /root/certbot-auto/certbot-auto renew") | crontab -


		        # Install nginx to define proxy rules (translation of subdomains/port 443 to several localhost ports in higher range)
                        echo "Installing Nginx to manage the SSL accesses" 
                        apt-get -y -q=2 install nginx
	                
			# Test and Enable teh nginx configuration
        		echo "Testing and Reloading Nginx congiguration (Give SSL access through proxy to R Studio Server and Hadoop/Spark admin pages)"
                        nginx -t
	                service nginx restart
 			
			# Close on the firewall everybody's access to port 443 
                        ufw delete allow 443
                        ufw reload
                        ufw status

 			# Find the IP address of the remote SSH connecction to open the firewall just to us
			# (The first IP address that has succeeded to connect to this server via ssh as root )
			ip=$(sudo grep -e "^.*Accepted.*$(whoami).* ssh2$" /var/log/auth.log  | head -1 | cut -d" " -f11)
                        echo "Opening the firewall on port 80 and 443 for your remote IP address $ip"
			ufw allow proto tcp from $ip to any port 80
			ufw allow proto tcp from $ip to any port 443
	                ufw reload
                        ufw status
	fi
else
        echo
        echo "************************************************************"
        echo "***** SKIP :  Step 12 : Install Let's Encrypt SSL      *****"
        echo "************************************************************"
        echo
fi



echo
echo "*******************************************"
echo "*****  Step 13 : install Dev tools    *****"
echo "*******************************************"
echo
apt-get -y -q=2 install git zip unzip autoconf automake cmake libtool curl zlib1g-dev  g++ vim aptitude arp-scan swig python-pip python-dev firefox


if ($CONDA) then
	echo
	echo "******************************************************"
	echo "*****  Step 14 : install anaconda, numpy, scikit *****"
	echo "******************************************************"
	echo
	if [ -d /home/$user_login/miniconda ]
	then 
	     echo "miniconda already installed"
	else
	     su - $user_login -c "cd /home/$user_login ; wget http://repo.continuum.io/miniconda/Miniconda3-3.7.0-Linux-x86_64.sh -O ./miniconda.sh"
	     su - $user_login -c "cd /home/$user_login ; bash ./miniconda.sh -b -p /home/$user_login/miniconda"
	     su - $user_login -c "cd /home/$user_login ; miniconda/bin/conda install numpy scikit-learn scipy"
	     # TODO su - $user_login -c "cd /home/$user_login ; miniconda/bin/conda create -n deeppy numpy scikit-learn scipy"
	     rm /home/$user_login/miniconda.sh
	fi
else
        echo
        echo "********************************************************"
        echo "*** SKIP Step 14 : install anaconda, numpy, scikit *****"
        echo "********************************************************"
        echo
fi


if ($CUDA) then
	echo
	echo "**************************************************************"
	echo "*****  Step 15 : Install NVIDIA Pascal GTX1080 drivers   *****"
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
        echo "*** SKIP Step 15 : Install NVIDIA Pascal GTX1080 drivers    *****"  
        echo "*****************************************************************"
        echo
fi


if ($CUDA ) then
        echo
        echo "**************************************************"
        echo "*****  Step 16 : NVIDIA GPU : Install CUDA   *****"
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
        echo "***** SKIP Step 16 : NVIDIA GPU : Install CUDA   *****"
        echo "******************************************************"
        echo
fi



if ($CUDA ) 
then
	echo
	echo "**************************************************"
	echo "*****  Step 17 : NVIDIA GPU : Install cuDNN  *****"
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
        echo "*** SKIP  Step 17 : Nvidia GPU : Install cuDNN ***"
        echo "**************************************************"
        echo
fi

if ($TF)
then
	echo
	echo "*************************************************************************************"
	echo "*****  Step 18 : Prepare TensorFlow Installation : Install Python, Numpy, ...   *****"
	echo "*************************************************************************************"
        echo
        apt-get -y -q=2 install python-numpy python-scipy python-matplotlib ipython ipython-notebook python-pandas python-sympy python-nose expect expect-dev
	pip -q install --upgrade pip 
        pip -q install scikit-learn

	echo
	echo "***********************************************************************"
	echo "*****  Step 19 : Prepare TensorFlow Installation : Install Bazel  *****"
	echo "***********************************************************************"
        echo
	echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list 
	curl https://storage.googleapis.com/bazel-apt/doc/apt-key.pub.gpg | sudo apt-key add - 
	apt-get -q=2 update 
	apt-get -y -q=2 install bazel 

	echo
	echo "*************************************************************"
	echo "*****     Step 20 : Build and Install TensorFlow        *****"
	echo "*************************************************************"
	echo
	echo
	if [ -d /home/$user_login/tensorflow ]
	then
	     rm -rf /home/$user_login/tensorflow
	fi
        su - $user_login -c "git clone --branch $TF_TAG https://github.com/tensorflow/tensorflow "
        
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
        echo "*** SKIP Step 18 : Prepare TensorFlow Installation : Install python ***"
        echo "***********************************************************************"
        echo
        echo "***********************************************************************"
        echo "*** SKIP Step 19 : Prepare TensorFlow Installation : Install Bazel  ***"
        echo "***********************************************************************"
        echo
        echo "*************************************************************"
        echo "*** SKIP  Step 20 : Build and Install TensorFlow        *****"
        echo "*************************************************************"
        echo
fi

if ($TORCH )
then
	echo
	echo "*************************************************************"
	echo "*****         Step 21 :  Build and Install Torch        *****"
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
        echo "*****    SKIP Step 21 :  Build and Install Torch        *****"
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




