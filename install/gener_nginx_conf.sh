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

# If we receive X-Forwarded-Proto, pass it through; otherwise, pass along the
# scheme used to connect to this server
map \$http_x_forwarded_proto \$proxy_x_forwarded_proto {
  default \$http_x_forwarded_proto;
  ''      \$scheme;
}
# If we receive Upgrade, set Connection to \"upgrade\"; otherwise, delete any
# Connection header that may have been passed to this server
map \$http_upgrade \$proxy_connection {
  default upgrade;
  '' close;
}
gzip_types text/plain text/css application/javascript application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
log_format vhost '\$host \$remote_addr - \$remote_user [\$time_local] '
                 '\"\$request\" \$status \$body_bytes_sent '
                 '\"\$http_referer\" \"\$http_user_agent\"';

# HTTP 1.1 support
proxy_http_version 1.1;
proxy_buffering off;
proxy_set_header Host \$http_host;
proxy_set_header Upgrade \$http_upgrade;
proxy_set_header Connection \$proxy_connection;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$proxy_x_forwarded_proto;

# Port 443 : access TensorBoard
server {
        listen 443 ssl; 
        ssl_certificate /etc/letsencrypt/live/tensorboard.$DOMAIN_NAME/cert.pem;
        ssl_certificate_key /etc/letsencrypt/live/tensorboard.$DOMAIN_NAME/privkey.pem;
        ssl_protocols  TLSv1.2;

        server_name tensorboard.$DOMAIN_NAME ;
        
        #Proxy
        location / {
                proxy_pass http://localhost:6006;
        }
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

# Upstreams
upstream jupyter.$DOMAIN_NAME {
        server jupyter.$DOMAIN_NAME ;
}

upstream cluster.$DOMAIN_NAME {
        server cluster.$DOMAIN_NAME ;
}


"
# End Nginx template

echo "Trying to generate nginx configuration file in /etc/nginx/sites-enabled/nginx_conf"
if [ -d /etc/nginx/sites-enabled/ ]
then
	echo "$TEMPLATE_NGINX" > /etc/nginx/sites-enabled/nginx_conf
else

	mkdir -p /etc/nginx/sites-enabled/
        echo "$TEMPLATE_NGINX" > /etc/nginx/sites-enabled/nginx_conf
fi




