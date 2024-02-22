#!/bin/bash

GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

#------------------------------- Public Functions-------------------

generateRandomString() {

local result_p=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
echo "$result_p"
}


    #Rano Port
generateRandomPort() {
    local min=1000
    local max=60000
    local range=$((max - min + 1))
    local result=$((RANDOM % range + min))
    echo "$result"
}


#------------------------------- Public Functions-------------------


#------------------------------- PRE INSTALL -------------------
preinstall(){

sudo apt update
sudo apt install -y apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mysql-server \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip \
                 toilet \
                 haproxy \
                 socat 
                }



#------------------------------- WordPress ONLY -------------------






xui_backup(){

   echo -e "Create a backup file in ${GREEN}/root/x-ui-backup/x-ui_backup.db${RESET}"
   sleep 2
   mkdir /root/x-ui-backup/
   cp /etc/x-ui/x-ui.db /root/x-ui-backup/x-ui_backup.db

}





#------------------------------- Get XUI(installed)) INFO -------------------
getinfo(){

   #backUp

    # Get user input for domain, xui panel path and port
    echo ""

    read -p "Enter domain for ${GREEN}WordPress${RESET} (a.example.com) ->> " user_domain
    domain=$(echo $user_domain | sed -E 's#^(https?://)?([^/]+)(/.*)?#\2#')

    #xui Path
    read -p "Enter Custom path for ${YELLOW}X-UI Panel${RESET} (e.g., /xui) ->> " user_xui_path
    xui_path="${user_xui_path//\//}"
   
    #check xui port
    while true; do
    read -p "Please Enter X-UI Panel Port ->>    " xui_port

    if [ "$xui_port" -eq 80 ] || [ "$xui_port" -eq 443 ]; then
        echo "The port should not be 80 or 443. Please change it from panel and  try again."
        continue
    else
        break # Exit the loop
    fi
    done


    #check subscription
    while true; do
    read -p "Do you use the subscription link ? (${GREEN}y${RESET}/${RED}n${RESET}):  " sub_status

    if [ "$sub_status" == "y" ] ; then
        # read -p "Enter Your Subscription path (e.g., /xui): " sub_path_i
        # sub_path="${sub_path_i//\//}"
        read -p "Enter Your Subscription port (e.g., 8443): " sub_port
        if [ "$sub_port" -eq 80 ] || [ "$sub_port" -eq 443 ]; then
        sub_port=$(generateRandomString)
        echo ""
        echo "Well, in order to continue using 80 or 443, you need to change the panel port to ${RED} ${sub_port} ${RESET}."
        echo "Now , Please login to xui panel and change the subscription port to ${RED} ${sub_port} ${RESET} from the subscription settings."   
        echo ""     
        read -p "${RED}If you did${RESET}, ${GREEN}press any key to continue...${RESET} " press_any_key
        read -p "${RED}َAre You Sure ? ${RESET}" press_any_key
        sub_code_status=111
        else
        echo ""
        echo "Do you want the sub port to be 443 in the end? This increases your security, but you have to give users the new subscription link." 
        echo ""
        echo "I want it to be on port ${RED}443${RESET}."
        echo "I want to stay on port ${sub_port} as before and And ${RED}I'm NOT going to change it${RESET}."
        read -p "Please choose an option (1 or 2): " sub_port_options
            if [ "$sub_port_options" -eq 1 ] ; then
                sub_port=443
                sub_code_status=222
            else
            echo ""
            echo "Okay, now tell me in what mode you use the subscription link?"
            echo "1. https (I have prepared a certificate for my domain/subdomain )"
            echo "2. http (without using certificate)" 
            echo ""
            read -p "Please choose an option (1 or 2): " sub_cert_options
                if [ "$sub_cert_options" -eq 1 ] ; then
                sub_code_status=333
                else
                sub_code_status=444
                fi
            
            fi
        
        fi

        read -p "Enter Your Subscription domain (e.g., sub.example.com): " sub_domain_i
        sub_domain=$(echo $sub_domain_i | sed -E 's#^(https?://)?([^/]+)(/.*)?#\2#')
        read -p "Enter path for xui panel (e.g., /xui): " user_sub_path
        sub_path="${user_sub_path//\//}"
        
    else
    sub_path=$(generateRandomString)
    sub_port=$(generateRandomPort)
    sub_domain=$domain
    sub_code_status=222
    break # Exit the loop
    fi
    done

    #Database Info
    read -p "Enter Database Name for WordPress:" database_name
    read -p "Enter Database UserName for WordPress:" database_user
    read -p "Enter Database Password for WordPress:" database_pass



}

ACME_install_Get_SSL(){

sudo systemctl stop apache2
sudo x-ui stop
curl https://get.acme.sh | sh -s email=info@$domain

ssl_path="/var/wui-certs"
mkdir -p "$ssl_path"

fullchain_path="$ssl_path/$domain-fullchain.pem"
key_path="$ssl_path/$domain.key"
mixed_ssl_path="$ssl_path/$domain-mixed.pem"
ca_path="$ssl_path/$domain-CA.ca"
certificate_path="$ssl_path/$domain-certeficateFile.cer"


if [ "$sub_domain" == "$domain" ] || [ "$sub_code_status" -eq 333 ] || [ "$sub_code_status" -eq 444 ] ; then

sub_fullchain_path=${fullchain_path}
sub_key_path=${key_path}
sub_mixed_ssl_path=${mixed_ssl_path}
sub_ca_path=${ca_path}
sub_certificate_path=${certificate_path}



else

sub_fullchain_path="$ssl_path/$sub_domain-fullchain.pem"
sub_key_path="$ssl_path/$sub_domain.key"
sub_mixed_ssl_path="$ssl_path/$sub_domain-mixed.pem"
sub_ca_path="$ssl_path/$sub_domain-CA.ca"
sub_certificate_path="$ssl_path/$sub_domain-certeficateFile.cer"

~/.acme.sh/acme.sh \
  --issue --force --standalone -d "$sub_domain" \
  --fullchain-file "$sub_fullchain_path" \
  --key-file "$sub_key_path"

cp /root/.acme.sh/${sub_domain}_ecc/$sub_domain.cer $sub_certificate_path
cp /root/.acme.sh/${sub_domain}_ecc/ca.cer $sub_ca_path
sudo bash -c "cat $sub_fullchain_path $sub_key_path > $sub_mixed_ssl_path"

fi

~/.acme.sh/acme.sh \
  --issue --force --standalone -d "$domain" \
  --fullchain-file "$fullchain_path" \
  --key-file "$key_path"

cp /root/.acme.sh/${domain}_ecc/$domain.cer $certificate_path
cp /root/.acme.sh/${domain}_ecc/ca.cer $ca_path
sudo bash -c "cat $fullchain_path $key_path > $mixed_ssl_path"

# sudo chmod 644 $fullchain_path
# sudo chmod 644 $certificate_path
# sudo chmod 600 $key_path
# sudo chmod 600 $mixed_ssl_path
# sudo chmod 600 $ca_path
sudo chown -R www-data:www-data /var/wui-certs

sudo systemctl start apache2
sudo x-ui start
}


installwordpress(){

wp_port=$(generateRandomPort)



    #------------ VARIABLES from GetInfo -----------------


    # $domain
    # $xui_path
    # $xui_port
    # $sub_status
    # $sub_path
    # $sub_port

    #certificate_path
    #fullchain_path
    # key_path
    # mixed_ssl_path
    # ca_path
    


 #--------------------DOwnload Worpress--------------
sudo mkdir -p /var/www/$domain
sudo chown -R www-data:www-data /var/www/$domain
curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz
tar -xzvf wordpress.tar.gz > /dev/null 2>&1
sudo mv wordpress/* /var/www/$domain/
sudo rm -rf wordpress wordpress.tar.gz


 #--------------------Apache Virtual Host--------------

cat <<EOF | sudo tee /etc/apache2/sites-available/$domain.conf

<VirtualHost 127.0.0.1:$wp_port>
    ServerName $domain
    DocumentRoot /var/www/$domain
    <Directory  /var/www/$domain>
        AllowOverride All
        Require all granted
    </Directory>

</VirtualHost>

EOF


ports_conf_path="/etc/apache2/ports.conf"

if [ ! -f "$ports_conf_path" ]; then
    sudo touch "$ports_conf_path"
fi

sudo bash -c "cat > $ports_conf_path <<EOF
Listen 127.0.0.1:$wp_port
EOF"

    #------------------------------MySQL Config------------------------

sudo mysql -u root <<EOF
CREATE DATABASE $database_name;
CREATE USER '$database_user'@'localhost' IDENTIFIED BY '$database_pass';
GRANT ALL PRIVILEGES ON $database_name.* TO '$database_user'@'localhost';
FLUSH PRIVILEGES;
EOF
sudo service mysql start


sudo -u www-data cp /var/www/$domain/wp-config-sample.php /var/www/$domain/wp-config.php
sudo -u www-data sed -i "s/database_name_here/${database_name}/g" /var/www/$domain/wp-config.php
sudo -u www-data sed -i "s/username_here/${database_user}/g" /var/www/$domain/wp-config.php
sudo -u www-data sed -i "s/password_here/${database_pass}/g" /var/www/$domain/wp-config.php


cat > /tmp/wp-additions.txt << EOF
define('WP_HOME','https://$domain');
define('WP_SITEURL','https://$domain');
define('WP_ALLOW_MULTISITE', true);
if( false !== strpos( \$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https' ) ) {
    \$_SERVER['HTTPS'] = 'on';
}
EOF

sed -i "/\* Add any custom values between this line and the \"stop editing\" line. \*/r /tmp/wp-additions.txt" /var/www/$domain/wp-config.php


sudo a2ensite $domain.conf
sudo a2dissite 000-default
sudo a2enmod rewrite 
sudo a2enmod ssl
sudo service apache2 reload
sudo systemctl restart apache2

}


haproxy(){

directory_path="/root/configs_tmp"

if [ ! -d "$directory_path" ]; then
    mkdir -p "$directory_path" 
    touch vmess_http_front.tmp vmess_http_backend.tmp all_tcp_tls_certs.tmp all_tcp_tls_front.tmp all_tcp_tls_backend.tmp
fi
 

sub_listen="127.0.0.2"
#sub config
if [ "$sub_code_status" -eq 111 ] || [ "$sub_code_status" -eq 222 ] ; then

    if [ "$sub_domain" == "$domain" ] ; then
    sub_cer_config=""
    else
    sub_cer_config=" crt $sub_mixed_ssl_path"
    fi

sub_config="
    acl path_sub path_beg /$sub_path/
    use_backend sub_backend if path_sub
"
sub_backend_config="

backend sub_backend
    mode http
    server sub $sub_listen:$sub_port 

"

elif [ "$sub_code_status" -eq 333 ] || [ "$sub_code_status" -eq 444 ] ; then
    sub_listen="none"
    sub_cer_config=""
    sub_config=""
    sub_backend_config=""


fi



echo "Configuring HAProxy..."
sudo mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    log /dev/log local0

defaults
    log global
    retry-on all-retryable-errors

    timeout connect 5s
    timeout client 50s
    timeout client-fin 50s
    timeout server 50s
    timeout tunnel 1h
    default-server init-addr none
    default-server inter 15s fastinter 2s downinter 5s rise 3 fall 3
    mode tcp

frontend http_front
    bind *:80
    mode tcp

    tcp-request inspect-delay 5s
    tcp-request content accept if HTTP

    acl is_wordpress hdr(host) -i $domain
    acl path_xui path_beg /$xui_path/

    #vmess_http_block_front_start


  
    #vmess_http_block_front_end

    use_backend xui_backend if path_xui
    use_backend wordpress_backend if is_wordpress
    #http_base_front
    default_backend wordpress_backend

    #vmess_http_block_backend_start



    #vmess_http_block_backend_end



frontend https_front_reality
    bind *:443
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }
    #reality_tcp_front_start

    #reality_tcp_front_end

#reality_tcp_backend_start

#reality_tcp_backend_end

frontend https_front
    bind *:443 ssl crt $mixed_ssl_path $sub_cer_config 
    #all_tcp_tls_certs_start

    #all_tcp_tls_certs_end
    mode http
    acl is_wordpress hdr(host) -i $domain
    acl path_xui path_beg /$xui_path/
    $sub_config
    use_backend xui_backend if path_xui
    use_backend wordpress_backend if is_wordpress

    #all_tcp_tls_front_start



    #all_tcp_tls_front_end
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    default_backend wordpress_backend


backend wordpress_backend
    mode http
    server wordpress 127.0.0.1:$wp_port 

backend xui_backend
    mode http
    server xui 127.0.0.2:$xui_port 

#sub_Backend
$sub_backend_config

#all_tcp_tls_backend_start

#all_tcp_tls_backend_end



EOF


sudo systemctl restart haproxy


}




 #------------ The order of execution of WordPress functions  -----------------

show_information(){
clear 
echo ""
echo "-------------------------- X-UI Database backup --------------------------------"
echo ""
echo "X-ui Backup file ->> /root/x-ui-backup/x-ui_backup.db"
echo ""
echo "------------------------------ WordPress ---------------------------------------"
echo ""
echo -e "${CYAN} WebSite URLs , Now you can open the site address and make additional WordPress settings!  ${RESET}"
echo -e "${GREEN} with https : https://${domain} ${RESET}"
echo -e "${GREEN} with http : http://${domain} ${RESET}"
echo ""
echo "----------------------------- X-UI Panel  --------------------------------------"
echo ""
echo -e "${CYAN} Xui Pannel URLs , Now you can open the XUI ,We strongly suggest to use https/tls mode to open the panel  ${RESET}"
echo -e "${GREEN} with https : https://${domain}/${xui_path}/ ${RESET}"
echo -e "${GREEN} with http : http://${domain}/${xui_path}/ ${RESET}"
echo ""
echo "---------------------------- Subscription --------------------------------------"
echo ""
echo -e "${CYAN} Subscription service configuration:  ${RESET}"
echo -e "${GREEN} Listen IP : $sub_listen"
echo -e "${GREEN} Subscription Port: $sub_port ${RESET}"
echo -e "${GREEN} Subscription Path : $sub_path ${RESET}"
echo ""
echo "--------------------------- Mysql Database -------------------------------------"
echo ""
echo -e "${GREEN} DatabaseName : ${database_name} ${RESET} "
echo -e "${GREEN} Database User : ${database_user} ${RESET}"
echo -e "${GREEN} Database Pass : ${database_pass} ${RESET}"
echo ""
echo "-------------------------------- SSl  ------------------------------------------"
echo ""
echo "${GREEN}Fullchain Path :${RESET}  $fullchain_path"
echo "${GREEN}Key Path :${RESET}  $key_path"
echo ""
echo ""

}




wordpress_only(){


   xui_file_path="/etc/x-ui/x-ui.db"
   backup_file_path="/root/x-ui-backup/x-ui_backup.db"
    if [ -f "$xui_file_path" ] ; then
    xui_backup
            if [ -f "$backup_file_path" ] ; then
            echo -e "${GREEN}The backup file was created successfully${RESET}"
            getinfo
            ACME_install_Get_SSL
                    if [ -f "$fullchain_path" ] ; then
                    installwordpress
                    haproxy
                    show_information
                    else
                    echo -e "Sorry, there was a problem receiving the certificate, please check your domain's DNS records and try again."
                    return
                    
                    fi

            else
            echo -e "${GREEN}Failed to create backup file!${RESET}"
            fi

    else
    echo -e "${GREEN}Please Intsall XUI First ${RESET}"
    fi

    
}






#------------------------------- WordPress + XUI  -------------------




#------------------------------- ADD Custom Config  -------------------


custom_config(){


ssl_path="/var/wui-certs"
haproxy_cfg="/etc/haproxy/haproxy.cfg"

mkdir -p "/etc/haproxy/configs_backup_wui"
haproxy_backup_file="/etc/haproxy/configs_backup_wui/haproxy_latest.cfg"


if [[ -f $haproxy_backup_file ]]; then

    suffix=1
    while [[ -f "${haproxy_backup_file}_${suffix}" ]]; do
        ((suffix++))
    done

    new_haproxy_backup_file="${haproxy_backup_file}_${suffix}"
else

    new_haproxy_backup_file=$haproxy_backup_file
fi


cp $haproxy_cfg $new_haproxy_backup_file


directory_path="/root/configs_tmp"

if [ ! -d "$directory_path" ]; then
    mkdir -p "$directory_path" 
fi
 


custom_config_menu() {
    while true; do
        echo "Please choose one of these options:"
        echo "1. Vmess TCP http header"
        echo "2. Trojan/Vless/Vmess WS TLS"
        echo "3. VLESS TCP/GRPC REALITY"
        echo "4. Back to the main menu"
        echo
        read -p "Enter your desired option (1,2..): " option_custom_config_menu

        case $option_custom_config_menu in
            1)
                vmess_tcp_http_insert
                break
                ;;
            2)
                all_tcp_tls_insert
                break
                ;;
            3)
                reality_tcp_insert
                break
                ;;
            4)
                echo "Returning to the main menu..."
                clear
                return  # or use 'break' if you want to exit the script completely
                ;;
            *)
                echo "Invalid option: $option_custom_config_menu. Please enter a valid option (1-4)."
                ;;
        esac
    done
}





# vmess tcp http

# vless/vmess/trojan ws tls
# vless/vmess/trojan tcp tls

# vless tcp reality
# vless grpc reality

# vless/vmess/trojan grpc tls


vmess_tcp_http_insert(){


directory_path="/root/configs_tmp"
listen_vmess_tcp_http="127.0.0.3"
vmess_http_port=$(generateRandomPort)
vmess_http_path=$(generateRandomString)

    echo "
#vmess_http_front_${vmess_http_port}_start
acl vmess_http_${vmess_http_port} path_beg /${vmess_http_path}
use_backend vmess_http_backend_${vmess_http_port} if vmess_http_${vmess_http_port}
#vmess_http_front_${vmess_http_port}_end
" >> $directory_path/vmess_http_front.tmp

    echo "
#vmess_http_backend_for_${vmess_http_port}_start
backend vmess_http_backend_${vmess_http_port}
    server vmess_http_${vmess_http_port} ${listen_vmess_tcp_http}:${vmess_http_port} send-proxy-v2
#vmess_http_backend_for_${vmess_http_port}_end
    " >> $directory_path/vmess_http_backend.tmp


front_file_vmess_http="${directory_path}/vmess_http_front.tmp"
backend_file_vmess_http="${directory_path}/vmess_http_backend.tmp"


temp_cfg=$(mktemp)


sed '/#vmess_http_block_front_start/,/#vmess_http_block_front_end/{//!d}' $haproxy_cfg | \
sed '/#vmess_http_block_backend_start/,/#vmess_http_block_backend_end/{//!d}' > $temp_cfg

awk -v front="$front_file_vmess_http" -v back="$backend_file_vmess_http" '
    /#vmess_http_block_front_end/ {
        while ((getline line < front) > 0) {
            print "    " line
        }
    }
    /#vmess_http_block_backend_end/ {
        while ((getline line < back) > 0) {
            print "    " line
        }
    }
    { print }
' $temp_cfg > $haproxy_cfg

rm $temp_cfg
sudo systemctl restart haproxy
clear
echo "${YELLOW}-------------------------------Vmess TCP http ----------------------------------------------${RESET}"
echo "Congratulations! It was successful. You can use this information to make your configuration."
echo "  ${BLUE} Listen IP ${RESET}: ${listen_vmess_tcp_http} "
echo "  ${BLUE} Port ${RESET}: ${vmess_http_port}"
echo "  ${BLUE} Path ${RESET}: ${vmess_http_path}"
echo "${YELLOW}--------------------------------------------------------------------------------------------${RESET}"
echo ""

}

all_tcp_tls_insert(){
listen_all_tcp_tls="127.0.0.3"
all_tcp_tls_port=$(generateRandomPort)
all_tcp_tls_path=$(generateRandomString)

    read -p "Please enter the config SNI :  " all_tcp_tls_sni
    read -p "Is the SIN value the same as your panel's subdomain? ( y / n )" sni_option

    all_tcp_tls_sni_fullchain_path="$ssl_path/$all_tcp_tls_sni-fullchain.pem"
    all_tcp_tls_sni_pvkey_path="$ssl_path/$all_tcp_tls_sni.key"
    all_tcp_tls_sni_mixed_key_path="$ssl_path/$all_tcp_tls_sni-mixed.pem"

        if [ "$sni_option" == "y" ] ; then

        echo "Ok, so there is no need to get a certificate"
        else

        get_ssl_for_configs "$all_tcp_tls_sni"
            if [ -f "${all_tcp_tls_sni_mixed_key_path}" ] ; then
                echo "
                bind *:443 ssl crt ${all_tcp_tls_sni_mixed_key_path}
                " >> $directory_path/all_tcp_tls_certs.tmp
            else
                echo -e "Sorry, there was a problem receiving the certificate, please check your domain's DNS records and try again."
                return 2
            fi

        fi

    echo "
#all_tcp_tls_front_${all_tcp_tls_port}_start
acl all_tcp_tls_${all_tcp_tls_port} path_beg /${all_tcp_tls_path}
use_backend all_tcp_tls_backend_${all_tcp_tls_port} if all_tcp_tls_${all_tcp_tls_port}
#all_tcp_tls_front_${all_tcp_tls_port}_end
" >> $directory_path/all_tcp_tls_front.tmp

    echo "
#all_tcp_tls_backend_${all_tcp_tls_port}_start
backend all_tcp_tls_backend_${all_tcp_tls_port}
    mode http
    server all_tcp_tls_server_${all_tcp_tls_port} ${listen_all_tcp_tls}:${all_tcp_tls_port} ssl verify none send-proxy-v2
#all_tcp_tls_backend_${all_tcp_tls_port}_end
    " >> $directory_path/all_tcp_tls_backend.tmp



# مسیرهای فایل

front_file_all_tcp_tls="${directory_path}/all_tcp_tls_front.tmp"
backend_file_all_tcp_tls="${directory_path}/all_tcp_tls_backend.tmp"
cert_file_all_tcp_tls="${directory_path}/all_tcp_tls_certs.tmp"
# ایجاد نسخه موقتی از فایل haproxy.cfg
temp_cfg=$(mktemp)

# حذف محتوای داخل بلوک‌ها
sed '/#all_tcp_tls_certs_start/,/#all_tcp_tls_certs_end/{//!d}' $haproxy_cfg | \
sed '/#all_tcp_tls_front_start/,/#all_tcp_tls_front_end/{//!d}' $haproxy_cfg | \
sed '/#all_tcp_tls_backend_start/,/#all_tcp_tls_backend_end/{//!d}' > $temp_cfg

# اضافه کردن محتوای فایل‌های tmp به بلوک‌های مربوطه
awk -v front="$front_file_all_tcp_tls" -v back="$backend_file_all_tcp_tls" -v crt="$cert_file_all_tcp_tls" '
    /#all_tcp_tls_front_end/ {
        while ((getline line < front) > 0) {
            print "    " line
        }
    }
    /#all_tcp_tls_backend_end/ {
        while ((getline line < back) > 0) {
            print "    " line
        }
    }
    /#all_tcp_tls_certs_end/ {
        while ((getline line < crt) > 0) {
            print "    " line
        }
    }
    { print }
' $temp_cfg > $haproxy_cfg

# پاک کردن فایل موقت
rm $temp_cfg
sudo systemctl restart haproxy
clear
echo "${YELLOW}---------------------------Vless /Trojan /Vmess WS(websocket) -----------------------------${RESET}"
echo "Congratulations! It was successful. You can use this information to make your configuration."
echo "  Port : ${all_tcp_tls_port}"
echo "  Listen IP : ${listen_all_tcp_tls} "
echo "  Path : ${all_tcp_tls_path}"
echo "  SNI : ${all_tcp_tls_sni}"
echo "  PublicKey Path : ${all_tcp_tls_sni_fullchain_path}"
echo "  PublicKey Path : ${all_tcp_tls_sni_pvkey_path}"
echo "${YELLOW}--------------------------------------------------------------------------------------------${RESET}"
echo ""
}

reality_tcp_insert(){

listen_reality_tcp="127.0.0.3"
reality_tcp_port=$(generateRandomPort)
read -p "Please enter the config SNI's : (seprate them with , ) " reality_tcp_sni_comma
read -p "slect and enter transmission : ( tcp / grpc ) " transmission_reality
reality_tcp_sni=$(echo $reality_tcp_sni_comma | tr ',' ' ')

    echo "
#reality_tcp_front_${reality_tcp_port}_start
acl reality_tcp_${reality_tcp_port} req.ssl_sni -i ${reality_tcp_sni}
use_backend reality_tcp_backend_${reality_tcp_port} if reality_tcp_${reality_tcp_port}
#reality_tcp_front_${reality_tcp_port}_end
" >> $directory_path/reality_tcp_front.tmp

if [ "$transmission_reality" == "tcp" ] ; then
    echo "
#reality_tcp_backend_${reality_tcp_port}_start
backend reality_tcp_backend_${reality_tcp_port}
    mode tcp
    server reality_tcp_backend_${reality_tcp_port} ${listen_reality_tcp}:${reality_tcp_port} send-proxy-v2 
#reality_tcp_backend_${reality_tcp_port}_end
" >> $directory_path/reality_tcp_backend.tmp
else
    echo "
#reality_tcp_backend_${reality_tcp_port}_start
backend reality_tcp_backend_${reality_tcp_port}
    mode tcp
    server reality_tcp_backend_${reality_tcp_port} ${listen_reality_tcp}:${reality_tcp_port}
#reality_tcp_backend_${reality_tcp_port}_end
" >> $directory_path/reality_tcp_backend.tmp
fi



front_file_reality_tcp="${directory_path}/reality_tcp_front.tmp"
backend_file_reality_tcp="${directory_path}/reality_tcp_backend.tmp"

# ایجاد نسخه موقتی از فایل haproxy.cfg
temp_cfg=$(mktemp)

# حذف محتوای داخل بلوک‌ها
sed '/#reality_tcp_front_start/,/#reality_tcp_front_end/{//!d}' $haproxy_cfg | \
sed '/#reality_tcp_backend_start/,/#reality_tcp_backend_end/{//!d}' > $temp_cfg

awk -v front="$front_file_reality_tcp" -v back="$backend_file_reality_tcp" '
    /#reality_tcp_front_end/ {
        while ((getline line < front) > 0) {
            print "    " line
        }
    }
    /#reality_tcp_backend_end/ {
        while ((getline line < back) > 0) {
            print "    " line
        }
    }
    { print }
' $temp_cfg > $haproxy_cfg

# پاک کردن فایل موقت
rm $temp_cfg
sudo systemctl restart haproxy
clear
echo "${YELLOW}---------------------------------- Vless Reality -----------------------------------------${RESET}"

echo "Congratulations! It was successful. You can use this information to make your configuration."
echo "  Listen IP : ${listen_reality_tcp} "
echo "  Port : ${reality_tcp_port}"
echo "  ServerNames: ${reality_tcp_sni_comma}"
echo    ""
echo "${YELLOW}---------------------------------------------------------------------------------------------${RESET}"
echo ""


}

get_ssl_for_configs(){

local domain_sni=$1
sudo systemctl stop haproxy
sudo systemctl stop apache2
sudo x-ui stop

~/.acme.sh/acme.sh \
  --issue --force --standalone -d "$domain_sni" \
  --fullchain-file "$ssl_path/$domain_sni-fullchain.pem" \
  --key-file "$ssl_path/$domain_sni.key"

sudo bash -c "cat $ssl_path/$domain_sni-fullchain.pem $ssl_path/$domain_sni.key > $ssl_path/$domain_sni-mixed.pem"

sudo systemctl start apache2
sudo systemctl restart haproxy
sudo x-ui start


}


}

#------------------------------- Main Menu-------------------




wordpress_with_xui(){
    
xui_port_auto=$(generateRandomPort)
sub_port_auto=$(generateRandomPort)
xui_path_auto=$(generateRandomString)
sub_path_auto=$(generateRandomString)
database_name_auto=$(generateRandomString)
database_user_auto=$(generateRandomString)
database_pass_auto=$(generateRandomString)

install_mhsanaei(){

echo "${GREEN}Installing MHSanaei (3XUI)${RESET}"
printf 'n\n' | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) > /dev/null 2>&1

}

install_alireza(){

echo "${GREEN}Installing Alireza (XUI)${RESET}"
printf 'n\n' | bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) > /dev/null 2>&1

}


get_info_auto(){


   #backUp

    # Get user input for domain, xui panel path and port
    
    read -p "Enter domain for WordPress & XUI  (example.com):" user_domain_auto
    domain_auto=$(echo $user_domain_auto | sed -E 's#^(https?://)?([^/]+)(/.*)?#\2#')
    read -p "Do you want to add domains for subscription link ? ( ${GREEN} y ${RESET}/ ${RED} n ${RESET}) ->> " user_sub_status_auto
    if [ "$user_sub_status_auto" == "n" ] ; then

   sub_domain_auto=${domain_auto}

    else
    read -p "Well, then enter the domain/subdomain of your subscription link (w.g. sub.example.com ) ->> " user_subs_domain_auto
    sub_domain_auto=$(echo $user_subs_domain_auto | sed -E 's#^(https?://)?([^/]+)(/.*)?#\2#')
    fi


}

ACME_install_Get_SSL_auto(){


sudo systemctl stop haproxy
sudo systemctl stop apache2
sudo x-ui stop
curl https://get.acme.sh | sh -s email=info@$domain_auto

ssl_path="/var/wui-certs"
mkdir -p "$ssl_path"

fullchain_path_auto="$ssl_path/$domain_auto-fullchain.pem"
key_path_auto="$ssl_path/$domain_auto.key"
mixed_ssl_path_auto="$ssl_path/$domain_auto-mixed.pem"
ca_path_auto="$ssl_path/$domain_auto-CA.ca"
certificate_path_auto="$ssl_path/$domain_auto-certeficateFile.cer"


if [ "$domain_auto" == "$sub_domain_auto" ] ; then

sub_fullchain_path_auto=${fullchain_path}
sub_key_path_auto=${key_path}
sub_mixed_ssl_path_auto=${mixed_ssl_path}
sub_ca_path_auto=${ca_path}
sub_certificate_path_auto=${certificate_path}

else

sub_fullchain_path_auto="$ssl_path/$sub_domain_auto-fullchain.pem"
sub_key_path_auto="$ssl_path/$sub_domain_auto.key"
sub_mixed_ssl_path_auto="$ssl_path/$sub_domain_auto-mixed.pem"
sub_ca_path_auto="$ssl_path/$sub_domain_auto-CA.ca"
sub_certificate_path_auto="$ssl_path/$sub_domain_auto-certeficateFile.cer"

~/.acme.sh/acme.sh \
  --issue --force --standalone -d "$sub_domain_auto" \
  --fullchain-file "$sub_fullchain_path_auto" \
  --key-file "$sub_key_path_auto"

cp /root/.acme.sh/${sub_domain_auto}_ecc/$sub_domain_auto.cer $sub_certificate_path_auto
cp /root/.acme.sh/${sub_domain_auto}_ecc/ca.cer $sub_ca_path_auto
sudo bash -c "cat $sub_fullchain_path_auto $sub_key_path_auto > $sub_mixed_ssl_path_auto"

fi

~/.acme.sh/acme.sh \
  --issue --force --standalone -d "$domain_auto" \
  --fullchain-file "$fullchain_path_auto" \
  --key-file "$key_path_auto"

cp /root/.acme.sh/${domain_auto}_ecc/$domain_auto.cer $certificate_path_auto
cp /root/.acme.sh/${domain_auto}_ecc/ca.cer $ca_path_auto
sudo bash -c "cat $fullchain_path_auto $key_path_auto > $mixed_ssl_path_auto"

sudo chown -R www-data:www-data /var/wui-certs

sudo systemctl start apache2
sudo x-ui start

}
installwordpress_auto(){

wp_port_auto=$(generateRandomPort)



 #--------------------DOwnload Worpress--------------
sudo mkdir -p /var/www/$domain_auto
sudo chown -R www-data:www-data /var/www/$domain_auto
curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz
tar -xzvf wordpress.tar.gz > /dev/null 2>&1
sudo mv wordpress/* /var/www/$domain_auto/
sudo rm -rf wordpress wordpress.tar.gz


 #--------------------Apache Virtual Host--------------

cat <<EOF | sudo tee /etc/apache2/sites-available/$domain_auto.conf

<VirtualHost 127.0.0.1:$wp_port_auto>
    ServerName $domain_auto
    DocumentRoot /var/www/$domain_auto
    <Directory  /var/www/$domain_auto>
        AllowOverride All
        Require all granted
    </Directory>

</VirtualHost>

EOF

    #------------------------------Apache Port Config------------------------

ports_conf_path="/etc/apache2/ports.conf"

if [ ! -f "$ports_conf_path" ]; then
    sudo touch "$ports_conf_path"
fi

sudo bash -c "cat > $ports_conf_path <<EOF
Listen 127.0.0.1:$wp_port_auto
EOF"

    #------------------------------MySQL Config------------------------

sudo mysql -u root <<EOF
CREATE DATABASE $database_name_auto;
CREATE USER '$database_user_auto'@'localhost' IDENTIFIED BY '$database_pass_auto';
GRANT ALL PRIVILEGES ON $database_name_auto.* TO '$database_user_auto'@'localhost';
FLUSH PRIVILEGES;
EOF
sudo service mysql start


sudo -u www-data cp /var/www/$domain_auto/wp-config-sample.php /var/www/$domain_auto/wp-config.php
sudo -u www-data sed -i "s/database_name_here/${database_name_auto}/g" /var/www/$domain_auto/wp-config.php
sudo -u www-data sed -i "s/username_here/${database_user_auto}/g" /var/www/$domain_auto/wp-config.php
sudo -u www-data sed -i "s/password_here/${database_pass_auto}/g" /var/www/$domain_auto/wp-config.php

cat > /tmp/wp-additions_auto.txt << EOF
define('WP_HOME','https://$domain_auto');
define('WP_SITEURL','https://$domain_auto');
define('WP_ALLOW_MULTISITE', true);
if( false !== strpos( \$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https' ) ) {
    \$_SERVER['HTTPS'] = 'on';
}
EOF

sed -i "/\* Add any custom values between this line and the \"stop editing\" line. \*/r /tmp/wp-additions_auto.txt" /var/www/$domain_auto/wp-config.php


sudo a2ensite $domain_auto.conf
sudo a2dissite 000-default
sudo a2enmod rewrite 
sudo a2enmod ssl
sudo service apache2 reload
sudo systemctl restart apache2

}


haproxy_auto(){

directory_path="/root/configs_tmp"

sub_listen_auto="127.0.0.2"
#sub config

    if [ "$sub_domain_auto" == "$domain_auto" ] ; then
    sub_cer_config_auto=""
    else
    sub_cer_config_auto=" crt $sub_mixed_ssl_path_auto"
    fi

sub_config_auto="
    acl path_sub path_beg /$sub_path_auto/
    use_backend sub_backend if path_sub
"
sub_backend_config_auto="

backend sub_backend
    mode http
    server sub $sub_listen_auto:$sub_port_auto 

"


echo "Configuring HAProxy..."
sudo mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    log /dev/log local0

defaults
    log global
    retry-on all-retryable-errors

    timeout connect 5s
    timeout client 50s
    timeout client-fin 50s
    timeout server 50s
    timeout tunnel 1h
    default-server init-addr none
    default-server inter 15s fastinter 2s downinter 5s rise 3 fall 3
    mode tcp

frontend http_front
    bind *:80
    mode tcp

    tcp-request inspect-delay 5s
    tcp-request content accept if HTTP

    acl is_wordpress hdr(host) -i $domain_auto
    acl path_xui path_beg /$xui_path_auto/

    #vmess_http_block_front_start


  
    #vmess_http_block_front_end

    use_backend xui_backend if path_xui
    use_backend wordpress_backend if is_wordpress
    #http_base_front
    default_backend wordpress_backend

    #vmess_http_block_backend_start



    #vmess_http_block_backend_end



frontend https_front_reality
    bind *:443
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }
    #reality_tcp_front_start

    #reality_tcp_front_end

#reality_tcp_backend_start

#reality_tcp_backend_end

frontend https_front
    bind *:443 ssl crt $mixed_ssl_path_auto $sub_cer_config_auto 
    #all_tcp_tls_certs_start

    #all_tcp_tls_certs_end
    mode http
    acl is_wordpress hdr(host) -i $domain_auto
    acl path_xui path_beg /$xui_path_auto/
    $sub_config_auto
    use_backend xui_backend if path_xui
    use_backend wordpress_backend if is_wordpress

    #all_tcp_tls_front_start



    #all_tcp_tls_front_end
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    default_backend wordpress_backend


backend wordpress_backend
    mode http
    server wordpress 127.0.0.1:$wp_port_auto 

backend xui_backend
    mode http
    server xui 127.0.0.2:$xui_port_auto 

#sub_Backend
$sub_backend_config_auto

#all_tcp_tls_backend_start

#all_tcp_tls_backend_end



EOF



sudo systemctl restart haproxy


}


change_xui_settings(){
xui_username=$(generateRandomString)
xui_password=$(generateRandomString)

/usr/local/x-ui/x-ui setting -port ${xui_port_auto}
echo "Change Username and PassWord"
sleep 1
/usr/local/x-ui/x-ui setting -username ${xui_username} -password ${xui_password}
echo ""
x-ui restart
}


show_information_auto(){
clear 
echo ""
echo "${CYAN}------------------------------ WordPress ---------------------------------------${RESET}"
echo ""
echo -e "${CYAN} WebSite URLs , Now you can open the site address and make additional WordPress settings!  ${RESET}"
echo -e "${GREEN} with https : https://${domain_auto} ${RESET}"
echo -e "${GREEN} with http : http://${domain_auto} ${RESET}"
echo ""
echo "${CYAN}----------------------------- X-UI Panel  --------------------------------------${RESET}"
echo ""
echo -e "${CYAN} Xui Pannel URLs , Now you can open the XUI ,We strongly suggest to use https/tls mode to open the panel  ${RESET}"
echo ""
echo -e "${RED} Unsecure(For first time) : http://${domain_auto}:${xui_port_auto} ${RESET}"
echo -e "${GREEN} Username : ${xui_username} ${RESET}"
echo -e "${GREEN} Password : ${xui_password} ${RESET}"
echo ""
echo -e "${GREEN} with https : https://${domain_auto}/${xui_path_auto}/ ${RESET}"
echo -e "${GREEN} with http : http://${domain_auto}/${xui_path_auto}/ ${RESET}"
echo ""
echo "${CYAN}---------------------------- Subscription --------------------------------------${RESET}"
echo ""
echo -e "${CYAN} About your subscription service:  ${RESET}"
echo -e "${GREEN} Listen IP : ${sub_listen_auto}"
echo -e "${GREEN} Subscription Port ( LISTEN ) : ${sub_port_auto} ${RESET}"
echo -e "${GREEN} Subscription path : ${sub_path_auto} ${RESET}"
echo ""
echo "${CYAN}--------------------------- Mysql Database -------------------------------------${RESET}"
echo ""
echo -e "${GREEN} DatabaseName : ${database_name_auto} ${RESET} "
echo -e "${GREEN} Database User : ${database_user_auto} ${RESET}"
echo -e "${GREEN} Database Pass : ${database_pass_auto} ${RESET}"
echo ""
echo "${CYAN}-------------------------------- SSl  ------------------------------------------${RESET}"
echo ""
echo "SSL for Panel"
echo ""
echo "${GREEN}Fullchain Path : ${RESET} ${fullchain_path_auto}"
echo "${GREEN}Key Path : ${RESET} ${key_path_auto}"
echo ""
echo "SSL for Subscription "
echo ""
echo "${GREEN}Subscription Fullchain Path : ${RESET} ${sub_fullchain_path_auto}"
echo "${GREEN}Subscription Key Path :${RESET}  ${sub_key_path_auto}"
echo ""
echo "You can find your Cert Keys in : ${RESET} ${ssl_path}"
echo ""




}






    while true; do
        echo ""
        echo "  ${YELLOW}Which X-UI Panel do you want?${RESET}"
        echo "${GREEN}      1.MHSanaei (3x-ui)${RESET}"
        echo "${BLUE}       2. Alireza0${RESET}"
        read -p "Please select it because ${YELLOW}I want to install it for you ${RESET}( ${GREEN}1${RESET} or${BLUE} 2${RESET} ) ->>  " xui_selection

        case $xui_selection in
            1)  
                clear
                install_mhsanaei
                get_info_auto
                ACME_install_Get_SSL_auto
                installwordpress_auto
                haproxy_auto
                change_xui_settings
                show_information_auto

                break
                ;;
            2)
                clear
                install_alireza
                get_info_auto
                ACME_install_Get_SSL_auto
                installwordpress_auto
                haproxy_auto
                change_xui_settings
                show_information_auto
                break
                ;;
            *)
                echo ""
                echo "Invalid option: $xui_selection. Please enter a valid option (1-4)."
                ;;
        esac
    done


}



get_ssl_global(){

sudo systemctl stop haproxy
sudo systemctl stop apache2
sudo x-ui stop
ssl_path="/var/wui-certs"
echo "OK , Now Please Enter your Domain/Subdomain "
read -p "Domain/Subdomain ( e.g. a.example.com) ->> " domain_global
~/.acme.sh/acme.sh \
  --issue --force --standalone -d "$domain_global" \
  --fullchain-file "$ssl_path/$domain_global-fullchain.pem" \
  --key-file "$ssl_path/$domain_global.key"

fullchain_path_global="/var/wui-certs/${domain_global}-fullchain.pem"
pvkey_path_global="/var/wui-certs/$domain_global.key"

    if [ -f "$fullchain_path_global" ] ; then
    clear
    echo "-------------------------------- SSl  ------------------------------------------"
    echo ""
    echo "${GREEN}Successfull ! ${RESET}"
    echo ""
    echo "Fullchain Path :  $fullchain_path_global"
    echo "Key Path :  $pvkey_path_global"
    echo ""
    return
        else
        echo -e "Sorry, there was a problem receiving the certificate, please check your domain's DNS records and try again."
    return
        fi

sudo systemctl restart haproxy
sudo systemctl restart apache2
sudo x-ui start


}






delete_config() {
haproxy_cfg="/etc/haproxy/haproxy.cfg"
directory_path="/root/configs_tmp"

read -p "Please Enter Inbound Port " port_to_remove
    # حذف بلوک از فایل‌های موقت
    sed -i "/#.*_${port_to_remove}_start/,/#.*_${port_to_remove}_end/d" $directory_path/*_front.tmp
    sed -i "/#.*_${port_to_remove}_start/,/#.*_${port_to_remove}_end/d" $directory_path/*_backend.tmp

    # حذف بلوک از فایل haproxy.cfg
    sed -i "/#.*_${port_to_remove}_start/,/#.*_${port_to_remove}_end/d" $haproxy_cfg

    # ری‌استارت مجدد haproxy
    sudo systemctl restart haproxy

    echo "Inbound associated with port $port_to_remove has been successfully removed."
}



menu(){


# Main menu
while true; do

    echo ""
    toilet -f mono9 -F gay " D   D   S"
    toilet -f mono9 -F gay " W + X-U I"
    echo -e "${RED}"
    echo "-----------------------------------------------------------------------------"
    echo "------------------------ Youtube : @DailyDigitalSkills ----------------------"
    echo "-----------------------------------------------------------------------------"
    echo -e "${RESET}"
    echo "Select an option:"
    echo ""
    echo "${GREEN}1. Install ( Wordpreess + XUI)${RESET}"
    echo "${YELLOW}2. Add or Delete Inbounds${RESET}"
    echo "${YELLOW}3. Edit Config Files${RESET}"
    echo "${CYAN}4. Restart Services${RESET}"
     echo "${CYAN}5. Service Status${RESET}"
    echo "${GREEN}6. Get SSL${RESET}"
    echo "${RED}7. Unistall${RESET}"
    echo "${RED}8. Exit${RESET}"
    echo ""
    echo ""
    read -p "Option: " menu_option


    case $menu_option in
        1)

                while true; do
                echo ""
                echo "  ${RED}Select an option:${RESET}"
                echo "      1. ${GREEN}I have already installed${RESET} the xui panel(Beta)"
                echo "      2. ${RED}I don't have xui panel ${RESET}, install it for me too"
                echo "      3. Back to main menu"
                echo ""
                read -p "    ${CYAN}Option: ${RESET}" install_option

                case $install_option in
                1) 
                wordpress_only
                ;;
                2)
                wordpress_with_xui
                ;;
                3)
                #! Back to main Menu
                break
                ;;
                *)
                echo "${RED}Invalid option, please try again.${RESET}"
                ;;
                esac
                done
        ;;


        2)
                 while true; do
                echo ""
                echo "  ${RED}Select an option:${RESET}"
                echo "      1. ${GREEN}Add Inbound${RESET} "
                echo "      2. ${RED}Delete Inbound ${RESET}"
                echo "      3. Back to main menu"
                echo ""
                read -p "    ${CYAN}Option: ${RESET}" inbound_option

                case $inbound_option in
                1) 
                custom_config
                custom_config_menu
                ;;
                2)
                delete_config
                ;;
                3)
                #! Back to main Menu
                break
                ;;
                *)
                echo "${RED}Invalid option, please try again.${RESET}"
                ;;
                esac
                done
        
        ;;
        3)
                while true; do
                echo ""
                echo "  ${RED}Select an option:${RESET}"
                echo "      1. ${GREEN}Haproxy config${RESET} "
                echo "      2. ${RED}Edit Inbound Temp Files ${RESET}"
                echo "      3. Back to main menu"
                echo ""
                read -p "    ${CYAN}Option: ${RESET}" inbound_view_option

                case $inbound_view_option in
                1) 
                haproxy_cfg="/etc/haproxy/haproxy.cfg"

                mkdir -p "/etc/haproxy/configs_backup_wui"
                haproxy_backup_file="/etc/haproxy/configs_backup_wui/haproxy_latest.cfg"


                if [[ -f $haproxy_backup_file ]]; then

                    suffix=1
                    while [[ -f "${haproxy_backup_file}_${suffix}" ]]; do
                        ((suffix++))
                    done

                    new_haproxy_backup_file="${haproxy_backup_file}_${suffix}"
                else

                    new_haproxy_backup_file=$haproxy_backup_file
                fi


                cp $haproxy_cfg $new_haproxy_backup_file
                clear
                nano /etc/haproxy/haproxy.cfg
                ;;
                2)

                cd /root/configs_tmp/
                ls -l
                read -p "Please insert file name(e.g. vmess_http_front.tmp) : " config_file_edit_path
                nano /root/configs_tmp/${config_file_edit_path}
                ;;
                3)
                #! Back to main Menu
                break
                ;;
                *)
                echo "${RED}Invalid option, please try again.${RESET}"
                ;;
                esac
                done
        ;;
        4)
            check_restart() {
                if systemctl restart "$1"; then
                    echo "Service $1 restarted successfully."
                else
                    echo "Failed to restart $1."
                    if [[ "$1" == "haproxy" ]]; then
                        read -p "Do you want to restore the latest backup for haproxy? (y/n) " answer_haproxy_faild
                        if [[ $answer_haproxy_faild == "y" ]]; then
                            restore_haproxy_backup
                        fi
                    fi
                fi
            }

            restore_haproxy_backup() {
                backup_path_haproxy_restore="/etc/haproxy/configs_backup_wui"
                latest_backup=$(ls -v $backup_path_haproxy_restore/haproxy_latest.cfg_* 2>/dev/null | tail -n 1)
                echo $latest_backup
                if [ -n $latest_backup ]; then
                    cp "$latest_backup" "/etc/haproxy/haproxy.cfg"
                    sleep 10
                    check_restart "haproxy"
                    if systemctl restart haproxy; then
                        echo "haproxy restored to the latest backup and restarted successfully."
                    else
                        echo "Failed to restart haproxy after restoration."
                    fi
                else
                    echo "No backup files found for haproxy."
                fi
            }
            
            check_restart "haproxy"
            check_restart "apache2"  
            check_restart "x-ui"
        ;;
        5)

        check_service_status() {
            service=$1
            status=$(systemctl is-active $service)
            if [ "$status" = "active" ]; then
                echo "$service is ${GREEN}running.${RESET}"
            else
                echo "$service is ${RED}not running.${RESET}"
            fi
        }

        # بررسی وضعیت Apache
        check_service_status apache2
        check_service_status haproxy
        check_service_status x-ui
        ;;
        6)
        get_ssl_global
        ;;
        7)
            read -p "Are You Sure to Unistall DDS-WUI? (${GREEN}yes${RESET}/${RED}no${RESET}): " answer

            if [ "$answer" == "yes" ]; then
            # اگر جواب yes بود، دستورات مورد نظر را اجرا کن
            echo "Oh ! Ok , No problem!"
            sudo unlink /usr/local/bin/wui-dds
            sudo rm -rf /var/wui-certs/
            sudo rm -rf /root/configs_tmp/

            packages=(
                "apache2"
                "ghostscript"
                "libapache2-mod-php"
                "mysql-server"
                "php"
                "php-bcmath"
                "php-curl"
                "php-imagick"
                "php-intl"
                "php-json"
                "php-mbstring"
                "php-mysql"
                "php-xml"
                "php-zip"
                "toilet"
                "haproxy"
                "socat"
            )

            for package in "${packages[@]}"; do
                echo "*** Delete$package ***"
                sudo apt remove --purge -y "$package"
            done

            sudo apt autoremove -y
            echo "Unistall Completed"
            exit 0
            else
            sudo dds-wui
            fi
        ;;
        8)
                echo -e "${CYAN}Exiting...${RESET}"
        exit 0
        ;;
        *)
        echo "Invalid option, please try again."
        ;;
    esac
done
}



preinstall
menu
