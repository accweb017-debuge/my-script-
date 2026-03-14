#!/bin/bash

# ၁။ Root Access
[[ $EUID -ne 0 ]] && exec sudo bash "$0" "$@"

# --- Configuration ---
BUG_HOST="m.googleapis.com"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=443
PATH_NAME="/sos-vless"
REAL_IP=$(curl -s ifconfig.me)

# ၂။ Bypass Link ထုတ်ခြင်း (သင်ပြတဲ့ Example အတိုင်း)
VLESS_KEY="vless://$UUID@$BUG_HOST:$PORT?type=ws&security=none&path=%2Fsos-vless&host=$REAL_IP&sni=$REAL_IP#S0S-GCP-BUG"

clear
echo -e "\e[1;36m[*] Deploying Bypass Node (BUG Method)...\e[0m"

# ၃။ Telegram ဆီ စာပို့ခြင်း (URL Encoding အမှန်ဖြင့်)
TEXT="🚀 <b>GCP BYPASS READY</b>%0A%0A<code>$VLESS_KEY</code>"
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$TEXT" -d "parse_mode=HTML" > /dev/null

# ၄။ Xray core & Config
apt-get update -y && apt-get install -y unzip curl > /dev/null 2>&1
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) > /dev/null 2>&1

mkdir -p /usr/local/etc/xray
cat <<EOF > /usr/local/etc/xray/config.json
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vless",
    "settings": { "clients": [{ "id": "$UUID" }], "decryption": "none" },
    "streamSettings": { 
        "network": "ws", 
        "wsSettings": { "path": "$PATH_NAME", "headers": { "Host": "$REAL_IP" } } 
    }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

# ၅။ Firewall & Service
systemctl restart xray
gcloud compute firewall-rules create allow-vless-bug-$(date +%s) --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 > /dev/null 2>&1

echo -e "\e[1;32m✅ အောင်မြင်စွာ Setup လုပ်ပြီးပါပြီ။\e[0m"
echo -e "\e[1;33mKey:\e[0m $VLESS_KEY"
rm -- "$0"
