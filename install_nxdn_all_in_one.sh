#!/bin/bash
set -e

### CONFIG ###
INSTALL_DIR="/usr/local/bin/NXDNReflector"
SERVICE="nxdnreflector"
USER="mmdvm"
REPO="https://github.com/nostar/DVReflectors.git"
DASHBOARD_REPO="https://github.com/ShaYmez/NXDNReflector-Dashboard2.git"
WWW_ROOT="/var/www/html"

echo "=== NXDNReflector All-in-One Installer ==="

### ROOT CHECK ###
if [[ $EUID -ne 0 ]]; then
  echo "Run dit script als root"
  exit 1
fi

### APT RESET (BELANGRIJK) ###
echo ">> Reset APT state"
apt clean
rm -rf /var/lib/apt/lists/*
apt update
apt --fix-broken install -y || true

### SYSTEM UPDATE ###
apt full-upgrade -y || true

### PACKAGES ###
apt install -y \
  git build-essential wget curl \
  apache2 php libapache2-mod-php \
  nodejs npm \
  whiptail logrotate ufw

### USER ###
if ! id "$USER" &>/dev/null; then
  adduser --disabled-password --gecos "" $USER
  echo "$USER:mmdvm" | chpasswd
fi
usermod -aG adm $USER

### FIREWALL ###
ufw allow ssh
ufw allow 41400/udp
ufw allow 80/tcp
ufw --force enable

### INSTALL NXDNReflector ###
mkdir -p $INSTALL_DIR
rm -rf /tmp/DVReflectors
git clone $REPO /tmp/DVReflectors
cp /tmp/DVReflectors/NXDNReflector/* $INSTALL_DIR/

cd $INSTALL_DIR
make
chown -R $USER:$USER $INSTALL_DIR

### CONFIG ###
cp NXDNReflector.ini /etc/NXDNReflector.ini || true

### SYSTEMD SERVICE (NATIVE) ###
cat >/etc/systemd/system/$SERVICE.service <<EOF
[Unit]
Description=NXDNReflector
After=network.target

[Service]
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/NXDNReflector /etc/NXDNReflector.ini
Restart=on-failure
RestartSec=5
StandardOutput=append:/var/log/NXDNReflector.log
StandardError=append:/var/log/NXDNReflector-error.log

[Install]
WantedBy=multi-user.target
EOF

### LOGROTATE ###
cat >/etc/logrotate.d/nxdnreflector <<EOF
/var/log/NXDNReflector*.log {
  daily
  rotate 14
  compress
  missingok
  notifempty
  create 0640 $USER adm
}
EOF

### NXDN DB UPDATE SCRIPT ###
cat >$INSTALL_DIR/nxdnupdate.sh <<'EOF'
#!/bin/bash
systemctl stop nxdnreflector
cd /usr/local/bin/NXDNReflector
mv nxdn.csv nxdn.old 2>/dev/null || true
wget -q -O nxdn.csv https://www.radioid.net/static/nxdn.csv
systemctl start nxdnreflector
EOF
chmod +x $INSTALL_DIR/nxdnupdate.sh

### DASHBOARD INSTALLATIE ###
echo ">> NXDNReflector-Dashboard2 installeren"

cd $WWW_ROOT
rm -rf NXDNReflector-Dashboard2
git clone $DASHBOARD_REPO
cd NXDNReflector-Dashboard2

npm install
npm run build:css

### DASHBOARD CONFIG AUTOMATISCH INSTELLEN ###
echo ">> Dashboard config.php aanmaken"

mkdir /var/www/html/NXDNReflector-Dashboard2/config
touch /var/www/html/NXDNReflector-Dashboard2/config/config.php

DASH_CONFIG="/var/www/html/NXDNReflector-Dashboard2/config/config.php"

cat > "$DASH_CONFIG" <<'EOF'
<?php
date_default_timezone_set('Europe/Amsterdam');

$reflectorName = "NXDNReflector";
$serviceName   = "nxdnreflector";

$logPath       = "/var/log/NXDNReflector.log";
$errorLogPath  = "/var/log/NXDNReflector-error.log";
$nxdnCSV       = "/usr/local/bin/NXDNReflector/nxdn.csv";
$iniFile       = "/etc/NXDNReflector.ini";

$refresh       = 10;
$showTG        = true;
$showNetwork   = true;
$debug         = false;
EOF

chown -R www-data:www-data /var/www/html/NXDNReflector-Dashboard2
chmod 640 "$DASH_CONFIG"


### SYSTEMD TIMERS ###
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

### ENABLE EVERYTHING ###
systemctl daemon-reload
systemctl enable --now nxdnreflector
systemctl enable --now nxdn-db-update.timer
systemctl restart apache2

echo ""
echo "=== INSTALLATIE KLAAR ==="
echo ""
echo "Reflector status : systemctl status nxdnreflector"
echo "Dashboard         : http://$(hostname -I | awk '{print $1}')/NXDNReflector-Dashboard2/"
echo "Config aanpassen  : sudo nano /etc/NXDNReflector.ini"
