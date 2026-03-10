#!/bin/bash
# JaCaL's Calibration Wizard Installer - Final Production Version

KLIPPER_EXTRAS_PATH="${HOME}/klipper/klippy/extras"
PRINTER_CONFIG_PATH="${HOME}/printer_data/config"
UI_DEST_PATH="${PRINTER_CONFIG_PATH}/cal_hub_ui"
FILES_DEST_PATH="${UI_DEST_PATH}/cal_files"

# ANSI Color Codes
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

LOCAL_IP=$(hostname -I | awk '{print $1}' | tr -d '[:space:]')
WIZARD_URL="http://${LOCAL_IP}:3258"

echo -e "${CYAN}=====================================${NC}"
echo -e "${BOLD} Installing JaCaL's Calibration Wizard...${NC}"
echo -e "${CYAN}=====================================${NC}"

# 1. Permissions Fix (Essential for Nginx access)
echo "-> Adjusting home directory permissions..."
chmod 755 ${HOME}
chmod 755 ${PRINTER_CONFIG_PATH}

# 2. Backend & Config
echo "-> Installing Klipper backend module..."
cp ./calibration_hub.py $KLIPPER_EXTRAS_PATH/

echo "-> Generating Klipper Macro..."
cat > $PRINTER_CONFIG_PATH/calibration_hub.cfg <<EOF
[calibration_hub]

[gcode_macro JACALS_WIZARD]
description: Launches JaCaL's Calibration Wizard
gcode:
    M118 ====================================
    M118 JaCaL's Calibration Wizard is live!
    M118 Click the link below to open the interface:
    M118 ${WIZARD_URL}
    M118 ====================================
EOF

# 3. Web UI & STLs
echo "-> Setting up Web UI and Calibration Files..."
mkdir -p $FILES_DEST_PATH
cp -r ./ui/* $UI_DEST_PATH/
cp ./*.stl $FILES_DEST_PATH/ 2>/dev/null
chmod -R 755 $UI_DEST_PATH

# 4. Klipper Integration
echo "-> Checking printer.cfg for includes..."
if ! grep -q "\[include calibration_hub.cfg\]" "$PRINTER_CONFIG_PATH/printer.cfg"; then
    sed -i '1i [include calibration_hub.cfg]' "$PRINTER_CONFIG_PATH/printer.cfg"
fi

if ! grep -q "\[force_move\]" "$PRINTER_CONFIG_PATH/printer.cfg"; then
    echo -e "\n[force_move]\nenable_force_move: True" >> "$PRINTER_CONFIG_PATH/printer.cfg"
fi

# 5. Nginx (Using the single-quote method to avoid redirect loops)
echo "-> Configuring Nginx..."
sudo rm -f /etc/nginx/conf.d/cal_hub.conf
sudo bash -c "cat > /etc/nginx/sites-available/cal_hub <<'EOF'
server {
    listen 3258;
    server_name _;
    root $UI_DEST_PATH;
    index index.html;

    absolute_redirect off;
    port_in_redirect off;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /cal_files/ {
        alias $FILES_DEST_PATH/;
        autoindex off;
    }
}
EOF"

sudo ln -sf /etc/nginx/sites-available/cal_hub /etc/nginx/sites-enabled/

echo "-> Restarting services..."
sudo systemctl restart nginx
sudo systemctl restart klipper

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}${BOLD} 🚀 INSTALLATION COMPLETE! 🚀${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "${YELLOW} JaCaL's Wizard is now LIVE at:${NC}"
echo -e "\n${CYAN}${BOLD} 👉 $WIZARD_URL 👈${NC}\n"
echo -e "${GREEN}======================================================${NC}\n"