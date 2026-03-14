#!/bin/sh
# JaCaL's Calibration Wizard Installer - Final Production Version

# ANSI Color Codes
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}=====================================${NC}"
echo -e "${BOLD} Installing JaCaL's Calibration Wizard...${NC}"
echo -e "${CYAN}=====================================${NC}"

# 1. Environment Detection & Variable Setup
if grep -iqE "openwrt|sonic|neptune" /etc/os-release /etc/issue 2>/dev/null || hostname | grep -iq "spad" || ! command -v sudo >/dev/null 2>&1; then
    echo "-> Creality Sonic Pad / Embedded environment detected."
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: You are logged in as 'creality'. You MUST be 'root' to install this."
        exit 1
    fi
    IS_SONIC_PAD=1
    SUDO_CMD=""
    KLIPPER_EXTRAS_PATH="/usr/share/klipper/klippy/extras"
    PRINTER_CONFIG_PATH="/root/printer_data/config"
    KLIPPER_RESTART_CMD="/etc/init.d/klipper_service restart"
    NGINX_RESTART_CMD="/etc/init.d/nginx restart"
    
    LOCAL_IP=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{print $7}' | tr -d '\n')
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(ifconfig 2>/dev/null | grep 'inet addr' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d: -f2 | head -n 1)
    fi
else
    echo "-> Standard Linux environment detected."
    IS_SONIC_PAD=0
    SUDO_CMD="sudo"
    KLIPPER_EXTRAS_PATH="${HOME}/klipper/klippy/extras"
    PRINTER_CONFIG_PATH="${HOME}/printer_data/config"
    KLIPPER_RESTART_CMD="$SUDO_CMD systemctl restart klipper"
    NGINX_RESTART_CMD="$SUDO_CMD systemctl restart nginx"
    LOCAL_IP=$(hostname -I | awk '{print $1}' | tr -d '[:space:]')
fi

if [ ! -d "$PRINTER_CONFIG_PATH" ]; then
    PRINTER_CONFIG_PATH=$(find / -name "printer.cfg" -type f 2>/dev/null | head -n 1 | xargs dirname)
fi

UI_DEST_PATH="${PRINTER_CONFIG_PATH}/cal_hub_ui"
FILES_DEST_PATH="${UI_DEST_PATH}/cal_files"
WIZARD_URL="http://${LOCAL_IP}:3258"

# 2. Permissions Fix
echo "-> Adjusting directory permissions..."
$SUDO_CMD chmod 755 ${HOME}
$SUDO_CMD chmod 755 ${PRINTER_CONFIG_PATH}

# 3. Backend & Config
echo "-> Installing Klipper backend module..."
$SUDO_CMD cp ./calibration_hub.py $KLIPPER_EXTRAS_PATH/

echo "-> Generating Klipper Macro..."
cat > $PRINTER_CONFIG_PATH/calibration_hub.cfg <<EOF
[calibration_hub]

[force_move]
enable_force_move: True

[gcode_macro JACALS_WIZARD]
description: Launches JaCaL's Calibration Wizard
gcode:
    M118 ====================================
    M118 JaCaL's Calibration Wizard is live!
    M118 Click the link below to open the interface:
    M118 ${WIZARD_URL}
    M118 ====================================
EOF

# 4. Web UI & STLs
echo "-> Setting up Web UI and Calibration Files..."
mkdir -p $FILES_DEST_PATH
cp -r ./ui/* $UI_DEST_PATH/
cp ./*.stl $FILES_DEST_PATH/ 2>/dev/null
$SUDO_CMD chmod -R 755 $UI_DEST_PATH

# 5. Klipper Integration
echo "-> Checking printer.cfg for includes..."
if ! grep -q "\[include calibration_hub.cfg\]" "$PRINTER_CONFIG_PATH/printer.cfg"; then
    sed -i '1i [include calibration_hub.cfg]' "$PRINTER_CONFIG_PATH/printer.cfg"
fi
echo "-> Increasing max extrusion limit..."
if ! grep -q "max_extrude_only_distance" "$PRINTER_CONFIG_PATH/printer.cfg"; then
    sed -i '/\[extruder\]/a max_extrude_only_distance: 150.0' "$PRINTER_CONFIG_PATH/printer.cfg"
fi

# 6. Nginx Setup
echo "-> Configuring Nginx..."
$SUDO_CMD mkdir -p /etc/nginx/conf.d
$SUDO_CMD rm -f /etc/nginx/conf.d/cal_hub.conf
$SUDO_CMD rm -f /etc/nginx/sites-enabled/cal_hub 2>/dev/null

$SUDO_CMD sh -c "cat > /etc/nginx/conf.d/cal_hub.conf <<'EOF'
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

# Surgically inject include into Creality's Nginx core file if missing
if [ "$IS_SONIC_PAD" -eq 1 ]; then
    if ! grep -q "include /etc/nginx/conf.d/\*.conf;" /etc/nginx/nginx.conf; then
        sed -i 's/http {/http {\n    include \/etc\/nginx\/conf.d\/*.conf;/g' /etc/nginx/nginx.conf
    fi
fi

# 7. Restart Services
echo "-> Restarting services..."
$NGINX_RESTART_CMD
$KLIPPER_RESTART_CMD

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}${BOLD} 🚀 INSTALLATION COMPLETE! 🚀${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "${YELLOW} JaCaL's Wizard is now LIVE at:${NC}"
echo -e "\n${CYAN}${BOLD} 👉 $WIZARD_URL 👈${NC}\n"
echo -e "${GREEN}======================================================${NC}\n"