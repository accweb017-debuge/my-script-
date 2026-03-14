#!/bin/bash

# =========================================================
# Configuration
# =========================================================
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=443
SNI="m.googleapis.com"
PATH_NAME="/sos-vless"

# 1. Update & Essential Tools (Screenshot ထဲက unzip error ကို ဖြေရှင်းရန်)
clear
echo -e "\e[1;36m[*] Installing Essential Tools & Optimizing...\e[0m"
sudo apt-get update -y > /dev/null
sudo apt-get install -y unzip curl > /dev/null

# System Optimization (BBR)
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p > /dev/null

# 2. Server Metadata
IP=$(curl -s ifconfig.me)
ISP=$(curl -s ipinfo.io/org)
CPU_CORES=$(nproc)
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')

# 3. Installing Xray Core (Fixed Installation)
echo -e "\e[1;36m[*] Deploying Xray Engine...\e[0m"
# Installation script ကို direct ခေါ်ပြီး error စစ်မည်
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) > /dev/null 2>&1

# 4. Config Creation
sudo mkdir -p /usr/local/etc/xray
cat <<EOF | sudo tee /usr/local/etc/xray/config.json > /dev/null
{
  "log": { "loglevel": "none" },
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [{ "id": "$UUID" }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": { "path": "$PATH_NAME" }
    }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

# 5. Service & Firewall
sudo systemctl restart xray 2>/dev/null
sudo systemctl enable xray 2>/dev/null
gcloud compute firewall-rules create allow-vless-$(date +%s) --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 2>/dev/null

# 6. Key Generation
VLESS_KEY="vless://$UUID@$IP:$PORT?type=ws&security=none&path=%2Fsos-vless&host=$SNI&sni=$SNI#$DEV_NAME-ULTRA"

# 7. Telegram Notification (စာသေချာပို့ရန် ပြင်ဆင်ထားသည်)
MESSAGE="<code>._______________   .________
 |   ____/\   _  \  |   ____/
 |____  \ /  /_\  \ |____  \ 
 /       \\  \_/   \/       \
/______  / \_____  /______  /
       \/        \/       \/</code>

🚀 <b>ULTRA NODE ACTIVE</b>
🌍 <b>ISP:</b> $ISP
🖥 <b>Specs:</b> $CPU_CORES Cores / ${RAM_TOTAL}MB RAM

✨ <b>VLESS KEY:</b>
<code>$VLESS_KEY</code>"

# စာပို့ခြင်း Result ကို စစ်ဆေးရန်
SEND_RESULT=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE" -d "parse_mode=HTML")

if [ "$SEND_RESULT" -eq 200 ]; then
    echo -e "\e[1;32m✅ Telegram ဆီ စာပို့ပြီးပါပြီ!\e[0m"
else
    echo -e "\e[1;31m❌ Telegram API Error: $SEND_RESULT\e[0m"
fi

rm -- "$0"
