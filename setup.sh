#!/bin/bash

# ၁။ Root Access
[[ $EUID -ne 0 ]] && exec sudo bash "$0" "$@"

# --- Configuration ---
DEV_NAME="S0S-BYPASS"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=443
BYPASS_ADDR="m.googleapis.com"
PATH_NAME="/sos-vless"
REAL_IP=$(curl -s ifconfig.me)

# VLESS Link တည်ဆောက်ခြင်း (Bypass Format)
VLESS_KEY="vless://$UUID@$BYPASS_ADDR:$PORT?type=ws&security=none&path=%2Fsos-vless&host=$REAL_IP&sni=$REAL_IP#$DEV_NAME"

clear
echo -e "\e[1;33m[*] Checking Telegram Connection...\e[0m"

# ၂။ Telegram ဆီ စာပို့ခြင်း (Error ရှာရလွယ်အောင် curl ကို အသေအချာပြင်ထားသည်)
SEND_MSG="🚀 <b>S0S GCP BYPASS ACTIVE</b>%0A%0A✨ <b>KEY:</b>%0A<code>$VLESS_KEY</code>%0A%0A🌐 <b>Real IP:</b> <code>$REAL_IP</code>"

RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$SEND_MSG" \
     -d "parse_mode=HTML")

if [[ $RESPONSE == *"\"ok\":true"* ]]; then
    echo -e "\e[1;32m✅ Telegram ဆီ စာပို့ပြီးပါပြီ။ Key ကို သွားယူပါ။\e[0m"
else
    echo -e "\e[1;31m❌ Telegram Error: $RESPONSE\e[0m"
    echo -e "\e[1;33m⚠️ Chat ID ဒါမှမဟုတ် Token ကို ပြန်စစ်ပါ။ Bot ကို /start နှိပ်ထားလား ကြည့်ပါ။\e[0m"
    exit 1
fi

# ၃။ Installation (Telegram စာရောက်မှ ဒါတွေလုပ်မယ်)
echo -e "\e[1;36m[*] Proceeding with Installation...\e[0m"
apt-get update -y && apt-get install -y unzip curl > /dev/null 2>&1
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) > /dev/null 2>&1

# ၄။ Xray Config
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

# ၅။ Firewall & Start
systemctl restart xray
gcloud compute firewall-rules create allow-sos-bypass --allow tcp:$PORT --priority 1000 --direction INGRESS --action ALLOW --source-ranges 0.0.0.0/0 > /dev/null 2>&1

echo -e "\e[1;32m✅ Setup Complete!\e[0m"
rm -- "$0"
