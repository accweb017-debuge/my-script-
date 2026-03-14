#!/bin/bash

# ၁။ Root သေချာပေါက်ဖြစ်အောင် အရင်စစ်ဆေးမည်
if [[ $EUID -ne 0 ]]; then
   echo "Error: Please run with sudo!"
   exit 1
fi

# --- Configuration ---
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=443
SNI="m.googleapis.com"
PATH_NAME="/sos-vless"

clear
echo -e "\e[1;32m[*] Root Access Granted. Installing...\e[0m"

# ၂။ လိုအပ်သော Tools များ ထည့်သွင်းခြင်း
apt-get update -y && apt-get install -y unzip curl sudo > /dev/null 2>&1

# ၃။ Xray Core ထည့်သွင်းခြင်း
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) > /dev/null 2>&1

# ၄။ Config File ဆောက်ခြင်း (Permission သေချာအောင် လုပ်ထားသည်)
mkdir -p /usr/local/etc/xray
cat <<EOF > /usr/local/etc/xray/config.json
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

# ၅။ Firewall & Start Service
systemctl stop xray 2>/dev/null
systemctl daemon-reload
systemctl restart xray
systemctl enable xray
gcloud compute firewall-rules create allow-vless-$(date +%s) --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 2>/dev/null

# ၆။ Metadata & Key
IP=$(curl -s ifconfig.me)
VLESS_KEY="vless://$UUID@$IP:$PORT?type=ws&security=none&path=%2Fsos-vless&host=$SNI&sni=$SNI#$DEV_NAME-ULTRA"

# ၇။ Telegram ပို့ခြင်း
MESSAGE="✅ <b>ROOT DEPLOY SUCCESS!</b>%0A🌐 IP: <code>$IP</code>%0A✨ KEY: <code>$VLESS_KEY</code>"
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE" -d "parse_mode=HTML" > /dev/null

echo -e "\e[1;32m✅ Done! Check Telegram.\e[0m"
rm -- "$0"
