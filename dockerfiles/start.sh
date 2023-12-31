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

# Use user-supplied port if set
if [ -n "${PORT}" ]; then
  echo "Setting webserver to user-supplied port ($PORT)"
  sudo sed -i 's/listen 20211/listen '"$PORT"'/g' /etc/nginx/conf.d/pialert.conf
fi

# Change web interface address if set
if [ -n "${LISTEN_ADDR}" ]; then
  echo "Setting webserver to user-supplied address ($LISTEN_ADDR)"
  sed -ie 's/listen /listen '"${LISTEN_ADDR}":'/g' /etc/nginx/conf.d/pialert.conf
fi

# Run the hardware vendors update at least once
echo "[INSTALL] Run the hardware vendors update"

# Check if ieee-oui.txt or ieee-iab.txt exist
if [ -f "$OUI_FILE" ]; then
  echo "The file ieee-oui.txt exists. Skipping update_vendors.sh..."
else
  echo "The file ieee-oui.txt does not exist. Running update_vendors..."

  # Run the update_vendors.sh script
  if [ -f "$INSTALL_DIR/pialert/back/update_vendors.sh" ]; then
    "$INSTALL_DIR/pialert/back/update_vendors.sh"
  else
    echo "update_vendors.sh script not found in $INSTALL_DIR."    
  fi
fi

FILEDB=$INSTALL_DIR/pialert/db/pialert.db

if [ -f "$FILEDB" ]; then
    chown -R www-data:www-data $INSTALL_DIR/pialert/db/pialert.db
fi

echo "[INSTALL] Copy starter pialert.db and pialert.conf if they don't exist"

# Copy starter pialert.db and pialert.conf if they don't exist
cp -n "$INSTALL_DIR/pialert/back/pialert.conf" "$INSTALL_DIR/pialert/config/pialert.conf" 
cp -n "$INSTALL_DIR/pialert/back/pialert.db"  "$INSTALL_DIR/pialert/db/pialert.db" 


# Check if buildtimestamp.txt doesn't exist
if [ ! -f "$INSTALL_DIR/pialert/front/buildtimestamp.txt" ]; then
    # Create buildtimestamp.txt
    date +%s > "$INSTALL_DIR/pialert/front/buildtimestamp.txt"
fi


# start PHP
/etc/init.d/php8.2-fpm start
/etc/init.d/nginx start

# Start Nginx and your application to start at boot (if needed)
# systemctl start nginx
# systemctl enable nginx

# # systemctl enable pi-alert
# sudo systemctl restart nginx

#  Activate the virtual python environment
source myenv/bin/activate

# Start the PiAlert python script
python $INSTALL_DIR/pialert/pialert/
