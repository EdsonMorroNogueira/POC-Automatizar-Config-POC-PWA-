#!/bin/bash

# Liberar Firewall nativo
sudo ufw allow OpenSSH
sudo ufw enable

# Instalar Nginx
sudo apt update
sudo apt install nginx -y

# Configurar Firewall do nginx
sudo ufw allow 'Nginx Full'

# Input do usuário para criação dinâmica do diretório de domínio
read -p "Digite o nome completo do domínio: " domainName

# Configurar diretório do domínio do site
sudo mkdir -p /var/www/$domainName/html
    # Garantindo permissões para o usuário 
sudo chown -R $USER:$USER /var/www/$domainName/html
    # Explicitando que apenas o usuário pode escrever no diretório +
    # enquanto o grupo e outros usuários apenas leitura e execução
sudo chmod -R 755 /var/www/$domainName

# Configurar server block
read -p "Digite o caminho de diretório do seu site até chegar antes do seu index.html: " pathIndex  
cat<<EOF > /etc/nginx/sites-available/$domainName
server {

        include mime.types;
        types {
                application/manifest+json webmanifest;
              }

        listen 80;
        listen [::]:80;

        root /var/www/$domainName/html/$pathIndex;
        index index.html index.htm index.nginx-debian.html;

        server_name $domainName www.$domainName;

        location / {
                    try_files $uri $uri/ =404;
        }
}
EOF

# Linkar a config do available com o enabled
sudo ln -s /etc/nginx/sites-available/$domainName /etc/nginx/sites-enabled/

# Evitando problema de hash bucket
cat<<EOF > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}

http {

        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;
        # server_tokens off;

        server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        ##
        # SSL Settings
        ##

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        ##
        # Logging Settings
        ##

        access_log /var/log/nginx/access.log;

        ##
        # Gzip Settings
        ##

        gzip on;

        # gzip_vary on;
        # gzip_proxied any;
        # gzip_comp_level 6;
        # gzip_buffers 16 8k;
        # gzip_http_version 1.1;
        # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

        ##
        # Virtual Host Configs
        ##

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}


#mail {
#       # See sample authentication script at:
#       # http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
#
#       # auth_http localhost/auth.php;
#       # pop3_capabilities "TOP" "USER";
#       # imap_capabilities "IMAP4rev1" "UIDPLUS";
#
#       server {
#               listen     localhost:110;
#               protocol   pop3;
#               proxy      on;
#       }
#
#       server {
#               listen     localhost:143;
#               protocol   imap;
#               proxy      on;
#       }
#}
EOF

# Reiniciar server nginx
sudo nginx -t
sudo systemctl restart nginx

# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Permitir conexão HTTPS com o dominio
sudo certbot --nginx -d $domainName
yes
yes

# Verificando renovação
sudo systemctl status certbot.timer
# Testar renovação
sudo certbot renew --dry-run

# Clonar repositório do github
read -p "Digite o endereço do projeto do github que será clonado: " gitPath
git clone $gitPath

# Copiar o projeto para dentro do diretório de domínio e html
read -p "Digite o nome do diretório inicial do projeto: " dirName
cp $dirName /var/www/$domainName/html

# Para reiniciar o servidor
sudo service nginx restart