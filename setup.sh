#!/bin/bash
# =============================================================================
# 🚀 S 0 S VLESS Auto Installer with Telegram Notification
# Version: 2.0-Fixed
# Description: Auto-install Xray Core with VLESS-WS config + Telegram send
# Usage: curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/setup.sh | sudo bash
# =============================================================================

set -e  # Error ဖြစ်ရင် ရပ်မယ်

# --- 🎨 Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- ⚙️ Configuration (လိုအပ်ရင် ပြင်ပါ) ---
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
UUID="${UUID:-$(cat /proc/sys/kernel/random/uuid)}"
PORT="${PORT:-443}"
SNI="${SNI:-m.googleapis.com}"
IP="${IP:-$(curl -s ifconfig.me)}"
WS_PATH="/sos-vless"

# --- 🧰 Helper Functions ---
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }

# --- 🔐 Root Check ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root!"
        exec sudo bash "$0" "$@"
        exit 1
    fi
}

# --- 🌐 Get Public IP ---
get_public_ip() {
    if command -v curl &> /dev/null; then
        curl -s --max-time 5 ifconfig.me || curl -s --max-time 5 ipinfo.io/ip || echo "127.0.0.1"
    else
        echo "127.0.0.1"
    fi
}
# --- 📤 Telegram Send Function (Fixed with proper escaping) ---
send_to_telegram() {
    local vless_link="$1"
    local ip_addr="$2"
    local uuid="$3"
    
    # Message format (Telegram MarkdownV2 compatible)
    local message="🚀 *${DEV_NAME} VLESS KEY READY*

\`${vless_link}\`

📍 *Server IP*: \`${ip_addr}\`
🔐 *UUID*: \`${uuid}\`
🌐 *SNI*: \`${SNI}\`
⚡ *Port*: \`${PORT}\`
🛤️ *Path*: \`${WS_PATH}\`

> Use with v2rayNG, NekoBox, Hiddify, etc."

    # Escape special chars for MarkdownV2: _ * [ ] ( ) ~ > # + - = | { } . !
    local escaped_msg
    escaped_msg=$(printf '%s' "$message" | sed 's/[_*[\]()~>#+=|{}.!-]/\\&/g')
    
    # API Call
    local response http_code
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${escaped_msg}" \
        -d "parse_mode=MarkdownV2" \
        --max-time 30)
    
    http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        return 0
    else
        log_warn "Telegram API returned: $http_code"
        return 1
    fi
}

# --- 📦 Install Dependencies ---
install_dependencies() {
    log_info "Updating package lists..."
    apt-get update -qq > /dev/null 2>&1
    
    log_info "Installing required packages..."
    apt-get install -y -qq curl wget unzip socat > /dev/null 2>&1}

# --- ⚡ Install Xray Core ---
install_xray() {
    log_info "Installing Xray Core..."
    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) @ install > /dev/null 2>&1
}

# --- ⚙️ Generate Xray Config ---
generate_config() {
    log_info "Generating Xray configuration..."
    
    mkdir -p /usr/local/etc/xray
    
    cat > /usr/local/etc/xray/config.json << EOF
{
  "inbounds": [{
    "port": ${PORT},
    "protocol": "vless",
    "settings": {
      "clients": [{ "id": "${UUID}", "level": 0, "email": "user@s0s" }],
      "decryption": "none",
      "fallbacks": []
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": {
        "path": "${WS_PATH}",
        "headers": { "Host": "${SNI}" }
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }, {
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }],
  "routing": {
    "rules": [{
      "type": "field",
      "ip": ["geoip:private"],
      "outboundTag": "blocked"    }]
  },
  "log": {
    "loglevel": "warning"
  }
}
EOF
}

# --- 🔥 Start Services & Firewall ---
start_services() {
    log_info "Starting Xray service..."
    systemctl daemon-reload
    systemctl enable --now xray > /dev/null 2>&1
    
    # Wait for service to start
    sleep 2
    
    if systemctl is-active --quiet xray; then
        log_success "Xray service is running!"
    else
        log_error "Xray service failed to start!"
        systemctl status xray --no-pager
        return 1
    fi
}

# --- 🧱 Configure Firewall ---
configure_firewall() {
    log_info "Configuring firewall..."
    
    # Allow port
    if command -v ufw &> /dev/null; then
        ufw allow ${PORT}/tcp > /dev/null 2>&1 || true
    fi
    
    # GCP Firewall (if gcloud is available)
    if command -v gcloud &> /dev/null; then
        gcloud compute firewall-rules create allow-vless-${PORT}-$(date +%s) \
            --allow tcp:${PORT} \
            --priority 1000 \
            --direction INGRESS \
            --action ALLOW \
            --source-ranges 0.0.0.0/0 > /dev/null 2>&1 || true
    fi
    
    # AWS Security Group hint
    if [[ -f /etc/amazon-release ]] || grep -q "Amazon Linux" /etc/os-release 2>/dev/null; then
        log_warn "AWS detected: Remember to allow port ${PORT} in Security Group!"
    fi}

# --- 🔗 Generate & Display VLESS Link ---
generate_vless_link() {
    echo "vless://${UUID}@${IP}:${PORT}?type=ws&security=none&path=${WS_PATH}&host=${SNI}&sni=${SNI}#${DEV_NAME}-ULTRA"
}

# --- 🎬 Main Execution ---
main() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════╗"
    echo "║  🚀 S 0 S VLESS Auto Installer v2.0   ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_root "$@"
    
    # Get IP if not set
    if [[ "$IP" == "127.0.0.1" ]] || [[ -z "$IP" ]]; then
        IP=$(get_public_ip)
    fi
    log_info "Detected IP: ${IP}"
    
    # Generate VLESS link for sending
    VLESS_LINK=$(generate_vless_link)
    
    # Send to Telegram FIRST (before any heavy install)
    log_info "Sending VLESS key to Telegram..."
    if send_to_telegram "$VLESS_LINK" "$IP" "$UUID"; then
        log_success "✅ Telegram notification sent!"
    else
        log_warn "⚠️ Telegram send failed - showing key below instead"
    fi
    
    # Install components
    install_dependencies
    install_xray
    generate_config
    start_services
    configure_firewall
    
    # Final output
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ Installation Completed Successfully! ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${YELLOW}📋 Your VLESS Configuration:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${VLESS_LINK}${NC}"    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${YELLOW}📊 Connection Info:${NC}"
    echo "  • IP Address : ${IP}"
    echo "  • Port       : ${PORT}"
    echo "  • UUID       : ${UUID}"
    echo "  • SNI/Host   : ${SNI}"
    echo "  • WS Path    : ${WS_PATH}"
    echo "  • Protocol   : VLESS + WebSocket\n"
    
    echo -e "${YELLOW}📱 If Telegram didn't receive the key, copy the link above!${NC}\n"
    
    # Optional: Self-delete script after execution
    # rm -f "$0"
}

# Run main function
main "$@"
