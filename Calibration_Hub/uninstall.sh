#!/bin/bash
# JaCaL's Calibration Wizard Uninstaller

KLIPPER_EXTRAS_PATH="${HOME}/klipper/klippy/extras"
PRINTER_CONFIG_PATH="${HOME}/printer_data/config"
UI_DEST_PATH="${PRINTER_CONFIG_PATH}/cal_hub_ui"

echo "====================================="
echo " Uninstalling JaCaL's Calibration Wizard..."
echo "====================================="

# 1. Remove Backend
echo "-> Removing Klipper backend module..."
rm -f $KLIPPER_EXTRAS_PATH/calibration_hub.py

# 2. Remove Configs
echo "-> Removing Klipper config..."
rm -f $PRINTER_CONFIG_PATH/calibration_hub.cfg

# 3. Remove UI
echo "-> Removing Web UI directory..."
rm -rf $UI_DEST_PATH

# 4. Clean Nginx
echo "-> Cleaning Nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/cal_hub
sudo rm -f /etc/nginx/sites-available/cal_hub
sudo rm -f /etc/nginx/conf.d/cal_hub.conf

# 5. Restore printer.cfg
echo "-> Removing include line from printer.cfg..."
sed -i '/\[include calibration_hub.cfg\]/d' "$PRINTER_CONFIG_PATH/printer.cfg"

# 6. Restart
echo "-> Restarting services..."
sudo systemctl restart nginx
sudo systemctl restart klipper

echo "====================================="
echo " Uninstallation Complete. Clean as a whistle."
echo "====================================="