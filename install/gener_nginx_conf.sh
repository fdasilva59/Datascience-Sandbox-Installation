#!/bin/bash

##########################################################################
####################   GENERATE NGINXCONFIGURATION   #####################
##########################################################################

DOMAIN_NAME=$1

[[ -z $DOMAIN_NAME ]] && empty=true || empty=false

if ($empty) then
	echo "Empty domain name : cannot generate nginx configuration" 
        exit
fi

# Begin Nginx template
TEMPLATE_NGINX=$"
# Port 80
server {
         listen 80 ;
         server_name $DOMAIN_NAME;
         return 301 https://\$server_name$request_uri;
}

# Port 443 : access R Studio Server
server {
	listen 443 ssl; 
	ssl_certificate /etc/letsencrypt/live/rstudio.$DOMAIN_NAME/cert.pem;
	ssl_certificate_key /etc/letsencrypt/live/rstudio.$DOMAIN_NAME/privkey.pem;
	ssl_protocols  TLSv1.2;

	server_name rstudio.$DOMAIN_NAME ;
        
        #Proxy
	location / {
	 	proxy_pass http://localhost:8787;
	}
}

# Port 443 : access hdfs
server {
        listen 443 ssl;
        ssl_certificate /etc/letsencrypt/live/hdfs.$DOMAIN_NAME/cert.pem;
        ssl_certificate_key /etc/letsencrypt/live/hdfs.$DOMAIN_NAME/privkey.pem;
        ssl_protocols  TLSv1.2;

        server_name hdfs.$DOMAIN_NAME ;

        #Proxy
        location / {
                proxy_pass http://localhost:50070;
        }
}

# Port 443 : access cluster hadoop
server {
        listen 443 ssl;
        ssl_certificate /etc/letsencrypt/live/cluster.$DOMAIN_NAME/cert.pem;
        ssl_certificate_key /etc/letsencrypt/live/cluster.$DOMAIN_NAME/privkey.pem;
        ssl_protocols  TLSv1.2;

        server_name cluster.$DOMAIN_NAME ;

        #Proxy
        location / {
                proxy_pass http://localhost:8088;
        }
}

# Port 443 : access jobs spark
server {
        listen 443 ssl;
        ssl_certificate /etc/letsencrypt/live/jobs.$DOMAIN_NAME/cert.pem;
        ssl_certificate_key /etc/letsencrypt/live/jobs.$DOMAIN_NAME/privkey.pem;
        ssl_protocols  TLSv1.2;

        server_name jobs.$DOMAIN_NAME ;

        #Proxy
        location / {
                proxy_pass http://localhost:4040;
        }
}

# Port 443 : access jupyter notebooks
server {
        listen 443 ssl;
        ssl_certificate /etc/letsencrypt/live/jupyter.$DOMAIN_NAME/cert.pem;
        ssl_certificate_key /etc/letsencrypt/live/jupyter.$DOMAIN_NAME/privkey.pem;
        ssl_protocols  TLSv1.2;

        server_name jupyter.$DOMAIN_NAME ;

        #Proxy
        location / {
                proxy_pass http://localhost:8888;
        }
}


"
# End Nginx template

echo "Trying to generate nginx configuration file in /etc/nginx/sites-enabled/server"
if [ -d /etc/nginx/sites-enabled/ ]
then
	echo "$TEMPLATE_NGINX" > /etc/nginx/sites-enabled/nginx_conf
else

	mkdir -p /etc/nginx/sites-enabled/
        echo "$TEMPLATE_NGINX" > /etc/nginx/sites-enabled/nginx_conf
fi




