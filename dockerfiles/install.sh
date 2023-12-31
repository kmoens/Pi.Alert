#!/usr/bin/env bash

echo "---------------------------------------------------------"
echo "[INSTALL]                                    Run start.sh"
echo "---------------------------------------------------------"


INSTALL_DIR=/home/pi  # Specify the installation directory here

# DO NOT CHANGE ANYTHING BELOW THIS LINE!
WEB_UI_DIR=/var/www/html/pialert
NGINX_CONFIG_FILE=/etc/nginx/conf.d/pialert.conf
OUI_FILE="/usr/share/arp-scan/ieee-oui.txt" # Define the path to ieee-oui.txt and ieee-iab.txt
# DO NOT CHANGE ANYTHING ABOVE THIS LINE!

# if custom variables not set we do not need to do anything
if [ -n "${TZ}" ]; then    
  FILECONF=$INSTALL_DIR/pialert/config/pialert.conf 
  if [ -f "$FILECONF" ]; then
    sed -ie "s|Europe/Berlin|${TZ}|g" $INSTALL_DIR/pialert/config/pialert.conf 
  else 
    sed -ie "s|Europe/Berlin|${TZ}|g" $INSTALL_DIR/pialert/back/pialert.conf_bak 
  fi
fi

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please use 'sudo'." 
    exit 1
fi

# Run setup scripts
echo "[INSTALL] Run setup scripts"

"$INSTALL_DIR/pialert/dockerfiles/user-mapping.sh"
#"$INSTALL_DIR/pialert/install/install_dependencies.sh" # if modifying this file transfer the chanegs into the root Dockerfile as well!

echo "[INSTALL] Setup NGINX"

# Remove default NGINX site if it is symlinked, or backup it otherwise
if [ -L /etc/nginx/sites-enabled/default ] ; then
  echo "Disabling default NGINX site, removing sym-link in /etc/nginx/sites-enabled"
  rm /etc/nginx/sites-enabled/default
elif [ -f /etc/nginx/sites-enabled/default ]; then
  echo "Disabling default NGINX site, moving config to /etc/nginx/sites-available"
  mv /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default.bkp_pialert
fi

# Clear existing directories and files
if [ -d $WEB_UI_DIR ]; then
  echo "Removing existing PiAlert web-UI"
  rm -R $WEB_UI_DIR
fi

if [ -f $NGINX_CONFIG_FILE ]; then
  echo "Removing existing PiAlert NGINX config"
  rm $NGINX_CONFIG_FILE
fi

# create symbolic link to the pialert install directory
ln -s $INSTALL_DIR/pialert/front $WEB_UI_DIR
# create symbolic link to NGINX configuaration coming with PiAlert
ln -s "$INSTALL_DIR/pialert/install/pialert.conf" /etc/nginx/conf.d/pialert.conf

# Check if buildtimestamp.txt doesn't exist
if [ ! -f "$INSTALL_DIR/pialert/front/buildtimestamp.txt" ]; then
    # Create buildtimestamp.txt
    date +%s > "$INSTALL_DIR/pialert/front/buildtimestamp.txt"
fi

