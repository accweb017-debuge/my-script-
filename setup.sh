#!/bin/bash

# ၁။ Root Access
[[ $EUID -ne 0 ]] && exec sudo bash "$0" "$@"

# --- Configuration ---
DEV_NAME="GCP-BYPASS"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=443
BYPASS_ADDR="m.googleapis.com"
PATH_NAME="/sos-vless"
REAL_IP=$(curl -s ifconfig.me)

# ၂။ Bypass VLESS Link တည်ဆောက်ခြင်း
# Address နေရာမှာ m.googleapis.com ကိုသုံးပြီး host/sni မှာ IP ကိုပြန်ညွှန်းမယ်
VLESS_KEY="vless://$UUID@$BYPASS_ADDR:$PORT?type=ws&security=none&path=$(echo -n $PATH_NAME | sed 's/\//%2F/g')&host=$REAL_IP&sni=$REAL_IP#$DEV_NAME"

clear
echo -e "\e[1;33m[*] Sending Bypass Key to Telegram...\e[0m"

# ၃။ Telegram ဆီ စာပို့ခြင်း
MESSAGE="🚀 <b>GCP BYPASS NODE</b>%0A%0A<code>$VLESS_KEY</code>%0A%0Aℹ️ <b>Fronting:</b> $BYPASS_ADDR%0Aℹ️ <b>Backend:</b> $REAL_IP"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$MESSAGE" \
     -d "parse_mode=HTML" > /dev/null

# ၄။ Xray core & Config setup
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
        "wsSettings": { 
            "path": "$PATH_NAME",
            "headers": { "Host": "$REAL_IP" }
        } 
    }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

# ၅။ Start & Firewall
systemctl restart xray
gcloud compute firewall-rules create allow-vless-bypass --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 > /dev/null 2>&1

echo -e "\e[1;32m✅ Bypass Script Applied Successfully!\e[0m"
rm -- "$0"
