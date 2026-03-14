#!/bin/bash
set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Configuration ---
DEV_NAME="S 0 S"
TOKEN="${TOKEN:-8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow}"
CHAT_ID="${CHAT_ID:-7130966571}"
UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
PORT="${PORT:-443}"
SNI="${SNI:-m.googleapis.com}"
IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "unknown")
WS_PATH="/sos-vless"

# --- Generate VLESS Key ---
VLESS_KEY="vless://${UUID}@${IP}:${PORT}?type=ws&security=none&path=%2Fsos-vless&host=${SNI}&sni=${SNI}#${DEV_NAME}-ULTRA"

# --- Send to Telegram Function ---
send_to_telegram() {
    local msg="$1"
    # URL Encode for Telegram (handles % & = # special chars)
    local encoded_msg=$(printf '%s' "$msg" | sed 's/[&%]/\\&/g')
    
    local http_code
    http_code=$(curl -s -w "%{http_code}" -o /dev/null -X POST \
        "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${encoded_msg}" \
        -d "parse_mode=MarkdownV2" \
        --max-time 30)
    
    [[ "$http_code" == "200" ]] && return 0 || return 1
}

# --- Prepare Message ---
TELEGRAM_MSG="🚀 *${DEV_NAME} VLESS KEY READY*

\`${VLESS_KEY}\`

📍 IP: \`$IP\`
🔐 UUID: \`$UUID\`
🌐 SNI: \`$SNI\`
⚡ Port: \`$PORT\`
🛤️ Path: \`${WS_PATH}\`"
# --- Step 1: Send Telegram First ---
clear
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🚀 S 0 S VLESS Auto Installer       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

if [ "$IP" != "unknown" ]; then
    echo -e "${YELLOW}[INFO] Sending VLESS key to Telegram...${NC}"
    if send_to_telegram "$TELEGRAM_MSG"; then
        echo -e "${GREEN}[✓] Telegram Sent Successfully!${NC}"
    else
        echo -e "${YELLOW}[!] Telegram Send Failed${NC}"
        echo -e "${YELLOW}Check Token & Chat ID${NC}"
    fi
else
    echo -e "${YELLOW}[!] Cannot get public IP${NC}"
    echo -e "${YELLOW}Key will display below${NC}"
fi

# --- Step 2: Install Dependencies ---
echo ""
echo -e "${YELLOW}[INSTALL] Updating packages...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y -qq unzip curl sudo > /dev/null 2>&1

echo -e "${YELLOW}[INSTALL] Installing Xray Core...${NC}"
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) @ install > /dev/null 2>&1

# --- Step 3: Write Config File ---
mkdir -p /usr/local/etc/xray

cat > /usr/local/etc/xray/config.json << 'CONFIGFILE'
{
  "inbounds": [{
    "port": PORT_PLACEHOLDER,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "UUID_PLACEHOLDER"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {
        "path": "PATH_PLACEHOLDER",
        "headers": {"Host": "SNI_PLACEHOLDER"}
      }
    },    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom"}],
  "log": {"loglevel": "warning"}
}
CONFIGFILE

# Replace placeholders with actual values
sed -i "s/PORT_PLACEHOLDER/${PORT}/g" /usr/local/etc/xray/config.json
sed -i "s/UUID_PLACEHOLDER/${UUID}/g" /usr/local/etc/xray/config.json
sed -i "s|PATH_PLACEHOLDER|${WS_PATH}|g" /usr/local/etc/xray/config.json
sed -i "s/SNI_PLACEHOLDER/${SNI}/g" /usr/local/etc/xray/config.json

# --- Step 4: Start Services ---
echo ""
echo -e "${YELLOW}[SERVICE] Starting Xray...${NC}"
systemctl daemon-reload > /dev/null 2>&1 || true
systemctl restart xray > /dev/null 2>&1 || true
systemctl enable xray > /dev/null 2>&1 || true

sleep 2
if systemctl is-active --quiet xray 2>/dev/null; then
    echo -e "${GREEN}[✓] Xray Service Running${NC}"
else
    echo -e "${RED}[✗] Xray Service Failed${NC}"
fi

# --- Step 5: Firewall ---
echo -e "${YELLOW}[FIREWALL] Configuring firewall rules...${NC}"
ufw allow ${PORT}/tcp > /dev/null 2>&1 || true
if command -v gcloud &> /dev/null; then
    gcloud compute firewall-rules create "allow-vless-${PORT}" \
        --allow tcp:${PORT} \
        --source-ranges 0.0.0.0/0 \
        --direction INGRESS \
        --action ALLOW \
        --priority 1000 \
        --description "Allow VLESS traffic" > /dev/null 2>&1 || true
fi

# --- Final Output ---
clear
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    ✅ INSTALLATION COMPLETED SUCCESSFULLY! ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📱 Check Your Telegram for Full VLESS Link${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""echo -e "${CYAN}${VLESS_KEY}${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 Connection Details:${NC}"
echo -e "  • Server IP : ${IP}"
echo -e "  • Port      : ${PORT}"
echo -e "  • UUID      : ${UUID}"
echo -e "  • SNI       : ${SNI}"
echo -e "  • WS Path   : ${WS_PATH}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔧 Service Management:${NC}"
echo -e "  Status:  sudo systemctl status xray"
echo -e "  Restart: sudo systemctl restart xray"
echo -e "  Logs:    journalctl -u xray -f"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Optional: Remove self
# rm -f "$0"
