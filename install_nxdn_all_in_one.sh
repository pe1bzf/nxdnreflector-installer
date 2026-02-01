#!/bin/bash
set -e

#############################################
# NXDNReflector – Definitieve Installer
# Raspberry Pi OS Lite / Debian >= 11
#############################################

### BASIS VARIABELEN
USER="mmdvm"
INSTALL_DIR="/usr/local/bin/NXDNReflector"
INI_FILE="/etc/NXDNReflector.ini"
SERVICE="nxdnreflector"
REPO="https://github.com/nostar/DVReflectors.git"
DASHBOARD_REPO="https://github.com/ShaYmez/NXDNReflector-Dashboard2.git"
WWW_ROOT="/var/www/html"

echo "=== NXDNReflector Definitieve Installatie ==="

### ROOT CHECK
if [[ $EUID -ne 0 ]]; then
  echo "Dit script moet als root worden uitgevoerd"
  exit 1
fi

#############################################
# APT RESET (voorkomt 404 mirror errors)
#############################################
echo ">> Reset APT"
apt clean
rm -rf /var/lib/apt/lists/*
apt update
apt --fix-broken install -y || true
apt full-upgrade -y || true

#############################################
# BENODIGDE PACKAGES
#############################################
echo ">> Installeer packages"
apt install -y \
  git build-essential wget curl \
  apache2 php libapache2-mod-php \
  nodejs npm \
  logrotate ufw whiptail dos2unix

#############################################
# USER mmdvm
#############################################
echo ">> Configureer gebruiker $USER"
if ! id "$USER" &>/dev/null; then
  adduser --disabled-password --gecos "" $USER
  echo "$USER:mmdvm" | chpasswd
fi
usermod -aG adm $USER

#############################################
# FIREWALL
#############################################
echo ">> Firewall instellen"
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 41400/udp
ufw --force enable

#############################################
# NXDNReflector INSTALLEREN
#############################################
echo ">> NXDNReflector installeren"
mkdir -p $INSTALL_DIR
rm -rf /tmp/DVReflectors
git clone $REPO /tmp/DVReflectors
cp /tmp/DVReflectors/NXDNReflector/* $INSTALL_DIR/

cd $INSTALL_DIR
make
chown -R $USER:$USER $INSTALL_DIR
chmod +x NXDNReflector

#############################################
# CONFIG FILE
#############################################
echo ">> Configuratiebestand plaatsen"
if [[ ! -f $INI_FILE ]]; then
  cp $INSTALL_DIR/NXDNReflector.ini $INI_FILE
fi

#############################################
# LOGGING – CRUCIAAL
#############################################
echo ">> Logging rechten instellen"

# directory rechten (NXDN interne logrotatie!)
chown root:adm /var/log
chmod 775 /var/log

# logfiles aanmaken
touch /var/log/NXDNReflector.log
touch /var/log/NXDNReflector-error.log
chown $USER:adm /var/log/NXDNReflector*.log
chmod 640 /var/log/NXDNReflector*.log

#############################################
# SYSTEMD SERVICE (self-daemonizing!)
#############################################
echo ">> systemd service installeren"

cat >/etc/systemd/system/$SERVICE.service <<EOF
[Unit]
Description=NXDNReflector
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/NXDNReflector $INI_FILE

# NXDNReflector daemoniseert zichzelf
RemainAfterExit=yes

Restart=on-failure
StandardOutput=append:/var/log/NXDNReflector.log
StandardError=append:/var/log/NXDNReflector-error.log

[Install]
WantedBy=multi-user.target
EOF

#############################################
# LOGROTATE
#############################################
echo ">> logrotate instellen"

cat >/etc/logrotate.d/nxdnreflector <<EOF
/var/log/NXDNReflector*.log {
  daily
  rotate 14
  compress
  delaycompress
  missingok
  notifempty
  create 0640 $USER adm
}
EOF

#############################################
# NXDN CSV UPDATE SCRIPT
#############################################
echo ">> NXDN database update script"

cat >$INSTALL_DIR/nxdnupdate.sh <<'EOF'
#!/bin/bash
set -e
systemctl stop nxdnreflector
cd /usr/local/bin/NXDNReflector
mv nxdn.csv nxdn.old 2>/dev/null || true
wget -q -O nxdn.csv https://www.radioid.net/static/nxdn.csv
chown mmdvm:mmdvm nxdn.csv
systemctl start nxdnreflector
EOF

chmod +x $INSTALL_DIR/nxdnupdate.sh

#############################################
# SYSTEMD TIMER – NXDN CSV
#############################################
echo ">> systemd timer (NXDN CSV)"

cat >/etc/systemd/system/nxdn-db-update.service <<EOF
[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/nxdnupdate.sh
EOF

cat >/etc/systemd/system/nxdn-db-update.timer <<EOF
[Timer]
OnCalendar=*-*-* 05:30
Persistent=true
[Install]
WantedBy=timers.target
EOF

#############################################
# DASHBOARD INSTALLATIE
#############################################
echo ">> Dashboard installeren"

cd $WWW_ROOT
rm -rf NXDNReflector-Dashboard2
git clone $DASHBOARD_REPO
cd NXDNReflector-Dashboard2
npm install
npm run build:css

#############################################
# DASHBOARD CONFIG
#############################################
echo ">> Dashboard config.php aanmaken"

sudo mkdir -p /var/www/html/NXDNReflector-Dashboard2/config
sudo touch /var/www/html/NXDNReflector-Dashboard2/config/config.php

cat >$WWW_ROOT/NXDNReflector-Dashboard2/config/config.php <<'EOF'
<?php
date_default_timezone_set('Europe/Amsterdam');

$reflectorName = "NXDNReflector";
$serviceName   = "nxdnreflector";

$logPath      = "/var/log/NXDNReflector.log";
$errorLogPath = "/var/log/NXDNReflector-error.log";
$nxdnCSV      = "/usr/local/bin/NXDNReflector/nxdn.csv";
$iniFile      = "/etc/NXDNReflector.ini";

$refresh = 10;
$debug   = false;
EOF

chown -R www-data:www-data $WWW_ROOT/NXDNReflector-Dashboard2
chmod 640 $WWW_ROOT/NXDNReflector-Dashboard2/config/config.php


####################################################################
# pas de NXDNReflector.ini aan met de juiste gegevens

read -p "Welke TG wilt u gebruiken ? (bijvoorbeeld 56789): " NEWTG
read -p "Op welke Poort wilt u luisteren ? (bijvoorbeeld 41400): " NEWPORT
sudo sed -i "s/^[[:space:]]*TG[[:space:]]*=.*/TG=$NEWTG/g" /etc/NXDNReflector.ini
sudo sed -i "s/^[[:space:]]*TGEnable[[:space:]]*=.*/TGEnable=$NEWTG/g" /etc/NXDNReflector.ini

sudo sed -i "s/^Port[[:space:]]*=.*/Port=$NEWPORT/g" /etc/NXDNReflector.ini
# echo "Alle Port en TG regels zijn aangepast naar: $NEWPORT e $NEWTG"
# Path naar de log-file
sudo sed -i "s|^[[:space:]]*FilePath[[:space:]]*=.*|FilePath=/var/log/|" /etc/NXDNReflector.ini
sudo sed -i "s|^[[:space:]]*Name[[:space:]]*=.*|Name=/usr/local/bin/NXDNReflector/nxdn.csv | " /etc/NXDNReflector.ini

echo ">> Initiële NXDN CSV downloaden"
sudo -u mmdvm wget -O /usr/local/bin/NXDNReflector/nxdn.csv \
https://www.radioid.net/static/nxdn.csv
chown mmdvm:mmdvm /usr/local/bin/NXDNReflector/nxdn.csv
chmod 644 /usr/local/bin/NXDNReflector/nxdn.csv
sudo sed -i "s|^Name=.*nxdn.csv|Name=/usr/local/bin/NXDNReflector/nxdn.csv|" /etc/NXDNReflector.ini

#############################################
# ENABLE & START
#############################################
echo ">> Services activeren"

systemctl daemon-reload
systemctl enable nxdnreflector
systemctl start nxdnreflector
systemctl enable --now nxdn-db-update.timer
systemctl restart apache2

#############################################
# EINDSTATUS
#############################################
echo ""
echo "=== INSTALLATIE VOLTOOID ==="
echo ""
echo "Reflector status : systemctl status nxdnreflector"
echo "Luistert op      : UDP 41400"
echo "Dashboard        : http://$(hostname -I | awk '{print $1}')/NXDNReflector-Dashboard2/"
echo "Config reflector aanpassen : sudo nano /etc/NXDNReflector.ini"
echo ""
echo "Van het dashboard (na installatie) altijd de setup afmaken en veiligheidshalve verwijderen"
echo "http://$(hostname -I | awk '{print $1}')/NXDNReflector-Dashboard2/setup.php"
echo ""
echo "Na aanpassing reflector config altijd:"
echo "  sudo systemctl restart nxdnreflector"
