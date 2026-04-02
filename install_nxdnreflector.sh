#!/bin/bash
set -e

#############################################
# NXDNReflector – Definitieve Installer
# Raspberry Pi OS Lite / Debian >= 11
#############################################

### VASTE PADEN (niet via dialoog)
MMDVM_USER="mmdvm"
INSTALL_DIR="/usr/local/bin/NXDNReflector"
INI_FILE="/etc/NXDNReflector.ini"
SERVICE="nxdnreflector"
REPO="https://github.com/nostar/DVReflectors.git"
DASHBOARD_REPO="https://github.com/ShaYmez/NXDNReflector-Dashboard2.git"

### ROOT CHECK
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root / Dit script moet als root worden uitgevoerd"
  exit 1
fi

#############################################
# WHIPTAIL BESCHIKBAAR MAKEN
#############################################
echo ">> Preparing installer (whiptail) ..."
apt-get -qq update
apt-get -qq install -y whiptail

#############################################
# TAALKEUZE – altijd als eerste scherm
#############################################
LANG_CHOICE=$(whiptail --title "Language / Taal / Dil" \
  --menu "\nPlease select your language:\nKies uw taal:\nLuetfen dilinizi secin:" \
  14 60 3 \
  "1" "Nederlands" \
  "2" "English" \
  "3" "Turkce" \
  3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }

case "$LANG_CHOICE" in
  1)
    T_WELCOME_TITLE="NXDNReflector Installatie"
    T_WELCOME_BODY="\nWelkom bij de NXDNReflector installatie.\n\nIn de volgende schermen vul je alle instellingen in.\nDaarna wordt alles automatisch geinstalleerd."
    T_TG_TITLE="Talk Group"
    T_TG_BODY="\nVoer het Talk Group nummer in:\n(bijv. 56789 voor Nederland)"
    T_TG_EMPTY="Talk Group mag niet leeg zijn."
    T_TG_NAN="Talk Group moet een getal zijn."
    T_PORT_TITLE="UDP Poort"
    T_PORT_BODY="\nVoer het UDP poortnummer in waarop de\nreflector moet luisteren:\n(standaard: 41400)"
    T_PORT_EMPTY="Poortnummer mag niet leeg zijn."
    T_PORT_NAN="Poortnummer moet een getal zijn."
    T_NAME_TITLE="Reflector naam"
    T_NAME_BODY="\nVoer de naam van jouw reflector in:\n(wordt getoond in het dashboard)"
    T_TZ_TITLE="Tijdzone"
    T_TZ_BODY="\nVoer de tijdzone in voor het dashboard:\n(bijv. Europe/Amsterdam, UTC, Europe/London)"
    T_DASH_TITLE="Dashboard locatie"
    T_DASH_BODY="\nWaar wil je het dashboard installeren?"
    T_DASH_ROOT="Hoofdmap  ->  http://<ip>/"
    T_DASH_SUB="Submap    ->  http://<ip>/nxdn/"
    T_SUBDIR_TITLE="Submap naam"
    T_SUBDIR_BODY="\nVoer de naam van de submap in:\n(bijv. nxdn -> http://<ip>/nxdn/)"
    T_UFW_TITLE="Firewall (UFW)"
    T_UFW_BODY="\nWil je UFW firewall inschakelen?\n\nPoorten die open worden gezet:\n  - SSH (22/tcp)\n  - HTTP (80/tcp)\n  - HTTPS (443/tcp)\n  - Reflector (UDP)"
    T_UFW_YES="Ja"
    T_UFW_NO="Nee"
    T_PASS_TITLE="mmdvm gebruiker wachtwoord"
    T_PASS_BODY="\nVoer een wachtwoord in voor de mmdvm gebruiker:\n(laat leeg voor standaard: mmdvm)"
    T_REFRESH_TITLE="Dashboard refresh"
    T_REFRESH_BODY="\nHoe vaak moet het dashboard verversen?\n(seconden, standaard: 10)"
    T_CSV_TITLE="NXDN CSV update tijd"
    T_CSV_BODY="\nOp welk tijdstip moet de NXDN database\ndagelijks worden bijgewerkt?\n(formaat: HH:MM, standaard: 05:30)"
    T_CONFIRM_TITLE="Bevestiging"
    T_CONFIRM_PROCEED="Wil je doorgaan met de installatie?"
    T_ABORTED="Installatie afgebroken. Start opnieuw om andere waarden in te vullen."
    T_SETUP_WARN_HEAD="!! BELANGRIJK NA DE INSTALLATIE !!"
    T_SETUP_WARN_BODY="Voer setup.php uit om het dashboard te activeren.\nZonder setup.php werkt het dashboard NIET!"
    T_DONE_TITLE="Installatie voltooid"
    T_DONE_HEAD="Installatie succesvol afgerond!"
    T_DONE_SETUP_HEAD="!! VOER NU EERST SETUP.PHP UIT !!"
    T_DONE_SETUP_WARN="Zonder setup.php werkt het dashboard NIET!"
    T_DONE_CMDS="Handige commando's"
    T_DONE_AFTER="Na wijziging van de config altijd"
    T_DONE_DAILY="dagelijks om"
    ;;
  2)
    T_WELCOME_TITLE="NXDNReflector Installer"
    T_WELCOME_BODY="\nWelcome to the NXDNReflector installation.\n\nThe following screens will ask for your settings.\nEverything will then be installed automatically."
    T_TG_TITLE="Talk Group"
    T_TG_BODY="\nEnter the Talk Group number:\n(e.g. 56789)"
    T_TG_EMPTY="Talk Group cannot be empty."
    T_TG_NAN="Talk Group must be a number."
    T_PORT_TITLE="UDP Port"
    T_PORT_BODY="\nEnter the UDP port number for the\nreflector to listen on:\n(default: 41400)"
    T_PORT_EMPTY="Port number cannot be empty."
    T_PORT_NAN="Port number must be a number."
    T_NAME_TITLE="Reflector name"
    T_NAME_BODY="\nEnter the name of your reflector:\n(displayed in the dashboard)"
    T_TZ_TITLE="Timezone"
    T_TZ_BODY="\nEnter the timezone for the dashboard:\n(e.g. Europe/Amsterdam, UTC, Europe/London)"
    T_DASH_TITLE="Dashboard location"
    T_DASH_BODY="\nWhere do you want to install the dashboard?"
    T_DASH_ROOT="Root dir  ->  http://<ip>/"
    T_DASH_SUB="Subdir    ->  http://<ip>/nxdn/"
    T_SUBDIR_TITLE="Subdirectory name"
    T_SUBDIR_BODY="\nEnter the subdirectory name:\n(e.g. nxdn -> http://<ip>/nxdn/)"
    T_UFW_TITLE="Firewall (UFW)"
    T_UFW_BODY="\nDo you want to enable the UFW firewall?\n\nPorts that will be opened:\n  - SSH (22/tcp)\n  - HTTP (80/tcp)\n  - HTTPS (443/tcp)\n  - Reflector (UDP)"
    T_UFW_YES="Yes"
    T_UFW_NO="No"
    T_PASS_TITLE="mmdvm user password"
    T_PASS_BODY="\nEnter a password for the mmdvm user:\n(leave empty for default: mmdvm)"
    T_REFRESH_TITLE="Dashboard refresh"
    T_REFRESH_BODY="\nHow often should the dashboard refresh?\n(seconds, default: 10)"
    T_CSV_TITLE="NXDN CSV update time"
    T_CSV_BODY="\nAt what time should the NXDN database\nbe updated daily?\n(format: HH:MM, default: 05:30)"
    T_CONFIRM_TITLE="Confirmation"
    T_CONFIRM_PROCEED="Do you want to proceed with the installation?"
    T_ABORTED="Installation cancelled. Restart to enter different values."
    T_SETUP_WARN_HEAD="!! IMPORTANT AFTER INSTALLATION !!"
    T_SETUP_WARN_BODY="Run setup.php to activate the dashboard.\nWithout setup.php the dashboard will NOT work!"
    T_DONE_TITLE="Installation complete"
    T_DONE_HEAD="Installation completed successfully!"
    T_DONE_SETUP_HEAD="!! RUN SETUP.PHP NOW FIRST !!"
    T_DONE_SETUP_WARN="Without setup.php the dashboard will NOT work!"
    T_DONE_CMDS="Useful commands"
    T_DONE_AFTER="After changing the config always run"
    T_DONE_DAILY="daily at"
    ;;
  3)
    T_WELCOME_TITLE="NXDNReflector Kurulum"
    T_WELCOME_BODY="\nNXDNReflector kurulumuna hos geldiniz.\n\nAsagidaki ekranlarda tum ayarlari gireceksiniz.\nDaha sonra her sey otomatik olarak kurulacaktir."
    T_TG_TITLE="Talk Group"
    T_TG_BODY="\nTalk Group numarasini girin:\n(ornek: 56789)"
    T_TG_EMPTY="Talk Group bos birakilamaz."
    T_TG_NAN="Talk Group bir sayi olmalidir."
    T_PORT_TITLE="UDP Portu"
    T_PORT_BODY="\nReflektorun dinleyecegi UDP port numarasini girin:\n(varsayilan: 41400)"
    T_PORT_EMPTY="Port numarasi bos birakilamaz."
    T_PORT_NAN="Port numarasi bir sayi olmalidir."
    T_NAME_TITLE="Reflektor adi"
    T_NAME_BODY="\nReflektorunuzun adini girin:\n(gosterge panelinde goruntulenecek)"
    T_TZ_TITLE="Saat dilimi"
    T_TZ_BODY="\nGosterge paneli icin saat dilimini girin:\n(ornek: Europe/Istanbul, UTC)"
    T_DASH_TITLE="Gosterge paneli konumu"
    T_DASH_BODY="\nGosterge panelini nereye kurmak istiyorsunuz?"
    T_DASH_ROOT="Ana dizin  ->  http://<ip>/"
    T_DASH_SUB="Alt dizin  ->  http://<ip>/nxdn/"
    T_SUBDIR_TITLE="Alt dizin adi"
    T_SUBDIR_BODY="\nAlt dizin adini girin:\n(ornek: nxdn -> http://<ip>/nxdn/)"
    T_UFW_TITLE="Guvenlik duvari (UFW)"
    T_UFW_BODY="\nUFW guvenlik duvarini etkinlestirmek istiyor musunuz?\n\nAcilacak portlar:\n  - SSH (22/tcp)\n  - HTTP (80/tcp)\n  - HTTPS (443/tcp)\n  - Reflektor (UDP)"
    T_UFW_YES="Evet"
    T_UFW_NO="Hayir"
    T_PASS_TITLE="mmdvm kullanici sifresi"
    T_PASS_BODY="\nmmdvm kullanicisi icin bir sifre girin:\n(varsayilan icin bos birakin: mmdvm)"
    T_REFRESH_TITLE="Panel yenileme suresi"
    T_REFRESH_BODY="\nGosterge paneli kac saniyede bir yenilensin?\n(saniye, varsayilan: 10)"
    T_CSV_TITLE="NXDN CSV guncelleme saati"
    T_CSV_BODY="\nNXDN veritabani gunluk olarak hangi saatte\nguncellensin?\n(bicim: HH:MM, varsayilan: 05:30)"
    T_CONFIRM_TITLE="Onay"
    T_CONFIRM_PROCEED="Kuruluma devam etmek istiyor musunuz?"
    T_ABORTED="Kurulum iptal edildi. Farkli degerler icin yeniden baslatIn."
    T_SETUP_WARN_HEAD="!! KURULUM SONRASI ONEMLI !!"
    T_SETUP_WARN_BODY="Paneli etkinlestirmek icin setup.php'yi calistirin.\nsetup.php olmadan panel CALISMAZ!"
    T_DONE_TITLE="Kurulum tamamlandi"
    T_DONE_HEAD="Kurulum basariyla tamamlandi!"
    T_DONE_SETUP_HEAD="!! SIMDI SETUP.PHP'YI CALISTIRIN !!"
    T_DONE_SETUP_WARN="setup.php olmadan panel CALISMAZ!"
    T_DONE_CMDS="Kullanisli komutlar"
    T_DONE_AFTER="Yapilandirma degistirildikten sonra her zaman"
    T_DONE_DAILY="her gun saat"
    ;;
esac

#############################################
# WELKOMSTSCHERM
#############################################
whiptail --title "$T_WELCOME_TITLE" --msgbox "$T_WELCOME_BODY" 14 60

#############################################
# CONFIGURATIE DIALOOG
#############################################

# --- 1. Talk Group ---
NEWTG=$(whiptail --title "$T_TG_TITLE" \
  --inputbox "$T_TG_BODY" \
  10 60 "56789" 3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }
[[ -z "$NEWTG" ]]             && { whiptail --msgbox "$T_TG_EMPTY" 8 50; exit 1; }
[[ ! "$NEWTG" =~ ^[0-9]+$ ]] && { whiptail --msgbox "$T_TG_NAN"   8 50; exit 1; }

# --- 2. UDP Poort ---
NEWPORT=$(whiptail --title "$T_PORT_TITLE" \
  --inputbox "$T_PORT_BODY" \
  10 60 "41400" 3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }
[[ -z "$NEWPORT" ]]             && { whiptail --msgbox "$T_PORT_EMPTY" 8 50; exit 1; }
[[ ! "$NEWPORT" =~ ^[0-9]+$ ]] && { whiptail --msgbox "$T_PORT_NAN"   8 50; exit 1; }

# --- 3. Reflector naam ---
REFLECTOR_NAME=$(whiptail --title "$T_NAME_TITLE" \
  --inputbox "$T_NAME_BODY" \
  10 60 "NXDNReflector" 3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }
[[ -z "$REFLECTOR_NAME" ]] && REFLECTOR_NAME="NXDNReflector"

# --- 4. Tijdzone ---
TIMEZONE=$(whiptail --title "$T_TZ_TITLE" \
  --inputbox "$T_TZ_BODY" \
  10 60 "Europe/Amsterdam" 3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }
[[ -z "$TIMEZONE" ]] && TIMEZONE="Europe/Amsterdam"

# --- 5. Dashboard locatie ---
DASH_LOCATION=$(whiptail --title "$T_DASH_TITLE" \
  --menu "$T_DASH_BODY" \
  12 60 2 \
  "ROOT"   "$T_DASH_ROOT" \
  "SUBMAP" "$T_DASH_SUB" \
  3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }

if [[ "$DASH_LOCATION" == "ROOT" ]]; then
  WWW_ROOT="/var/www/html"
  DASH_SUBDIR=""
else
  DASH_SUBDIR=$(whiptail --title "$T_SUBDIR_TITLE" \
    --inputbox "$T_SUBDIR_BODY" \
    10 60 "nxdn" 3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }
  [[ -z "$DASH_SUBDIR" ]] && DASH_SUBDIR="nxdn"
  WWW_ROOT="/var/www/html/${DASH_SUBDIR}"
fi

# --- 6. Firewall ---
if whiptail --title "$T_UFW_TITLE" --yesno "$T_UFW_BODY" 14 60; then
  ENABLE_UFW=true
  UFW_LABEL="$T_UFW_YES"
else
  ENABLE_UFW=false
  UFW_LABEL="$T_UFW_NO"
fi

# --- 7. mmdvm wachtwoord ---
MMDVM_PASS=$(whiptail --title "$T_PASS_TITLE" \
  --passwordbox "$T_PASS_BODY" \
  10 60 3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }
[[ -z "$MMDVM_PASS" ]] && MMDVM_PASS="mmdvm"

# --- 8. Dashboard refresh ---
DASH_REFRESH=$(whiptail --title "$T_REFRESH_TITLE" \
  --inputbox "$T_REFRESH_BODY" \
  10 60 "10" 3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }
[[ -z "$DASH_REFRESH" || ! "$DASH_REFRESH" =~ ^[0-9]+$ ]] && DASH_REFRESH=10

# --- 9. CSV update tijd ---
CSV_TIME=$(whiptail --title "$T_CSV_TITLE" \
  --inputbox "$T_CSV_BODY" \
  10 60 "05:30" 3>&1 1>&2 2>&3) || { echo "Cancelled."; exit 1; }
[[ -z "$CSV_TIME" ]] && CSV_TIME="05:30"
CSV_HOUR=$(echo "$CSV_TIME" | cut -d: -f1)
CSV_MIN=$(echo  "$CSV_TIME" | cut -d: -f2)

#############################################
# SAMENVATTING – setup.php prominent erin
#############################################
if [[ "$DASH_LOCATION" == "ROOT" ]]; then
  SETUP_URL_DISPLAY="http://<ip>/setup.php"
else
  SETUP_URL_DISPLAY="http://<ip>/${DASH_SUBDIR}/setup.php"
fi

whiptail --title "$T_CONFIRM_TITLE" --yesno \
"  Talk Group    : TG $NEWTG
  UDP Poort     : $NEWPORT
  Naam          : $REFLECTOR_NAME
  Tijdzone      : $TIMEZONE
  Dashboard     : http://<ip>/${DASH_SUBDIR}
  Firewall UFW  : $UFW_LABEL
  mmdvm pass    : $MMDVM_PASS
  Refresh       : ${DASH_REFRESH}s
  CSV update    : $CSV_TIME

  ================================================
  $T_SETUP_WARN_HEAD
  $T_SETUP_WARN_BODY
  --> $SETUP_URL_DISPLAY
  ================================================

  $T_CONFIRM_PROCEED" \
  30 68 || { whiptail --msgbox "$T_ABORTED" 8 62; exit 1; }

#############################################
# INSTALLATIE START
#############################################
clear
echo "=== NXDNReflector Installer ==="
echo "  TG   : $NEWTG  |  Port : $NEWPORT"
echo "  Dash : $WWW_ROOT"
echo ""

#############################################
# APT
#############################################
echo ">> APT reset & update"
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update
apt-get --fix-broken install -y || true
apt-get full-upgrade -y || true

echo ">> Packages installeren"
apt-get install -y \
  git build-essential wget curl \
  apache2 php libapache2-mod-php \
  nodejs npm \
  logrotate ufw whiptail dos2unix

#############################################
# USER mmdvm
#############################################
echo ">> Gebruiker $MMDVM_USER aanmaken"
if ! id "$MMDVM_USER" &>/dev/null; then
  adduser --disabled-password --gecos "" $MMDVM_USER
fi
echo "$MMDVM_USER:$MMDVM_PASS" | chpasswd
usermod -aG adm $MMDVM_USER

#############################################
# FIREWALL
#############################################
if [[ $ENABLE_UFW == true ]]; then
  echo ">> Firewall instellen"
  ufw allow ssh
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow ${NEWPORT}/udp
  ufw --force enable
else
  echo ">> Firewall overgeslagen"
fi

#############################################
# NXDNReflector BOUWEN
#############################################
echo ">> NXDNReflector bouwen & installeren"
mkdir -p $INSTALL_DIR
rm -rf /tmp/DVReflectors
git clone $REPO /tmp/DVReflectors
cp /tmp/DVReflectors/NXDNReflector/* $INSTALL_DIR/
cd $INSTALL_DIR
make
chown -R $MMDVM_USER:$MMDVM_USER $INSTALL_DIR
chmod +x NXDNReflector

#############################################
# INI CONFIGURATIE
#############################################
echo ">> NXDNReflector.ini configureren"
if [[ ! -f $INI_FILE ]]; then
  cp $INSTALL_DIR/NXDNReflector.ini $INI_FILE
fi
sed -i "s/^[[:space:]]*TG[[:space:]]*=.*/TG=$NEWTG/g"             $INI_FILE
sed -i "s/^[[:space:]]*TGEnable[[:space:]]*=.*/TGEnable=$NEWTG/g" $INI_FILE
sed -i "s/^Port[[:space:]]*=.*/Port=$NEWPORT/g"                    $INI_FILE
sed -i "s|^[[:space:]]*FilePath[[:space:]]*=.*|FilePath=/var/log/|"                       $INI_FILE
sed -i "s|^[[:space:]]*Name[[:space:]]*=.*|Name=/usr/local/bin/NXDNReflector/nxdn.csv|"  $INI_FILE

#############################################
# LOGGING
#############################################
echo ">> Logging rechten instellen"
usermod -aG adm www-data
chown root:adm /var/log
chmod 775 /var/log
touch /var/log/NXDNReflector.log
touch /var/log/NXDNReflector-error.log
chown $MMDVM_USER:adm /var/log/NXDNReflector*.log
chmod 640 /var/log/NXDNReflector*.log

#############################################
# SYSTEMD SERVICE
#############################################
echo ">> systemd service aanmaken"
cat >/etc/systemd/system/$SERVICE.service <<EOF
[Unit]
Description=NXDNReflector
After=network.target

[Service]
Type=simple
User=$MMDVM_USER
Group=$MMDVM_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/NXDNReflector $INI_FILE
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
  create 0640 $MMDVM_USER adm
  postrotate
    chown $MMDVM_USER:adm /var/log/NXDNReflector*.log 2>/dev/null || true
    chmod 640 /var/log/NXDNReflector*.log 2>/dev/null || true
  endscript
}
EOF

#############################################
# NXDN CSV UPDATE SCRIPT
#############################################
echo ">> nxdnupdate.sh aanmaken"
cat >$INSTALL_DIR/nxdnupdate.sh <<'NXDNEOF'
#!/bin/bash
set -e
INSTALL_DIR="/usr/local/bin/NXDNReflector"
CSV_URL="https://www.radioid.net/static/nxdn.csv"
CSV_FILE="$INSTALL_DIR/nxdn.csv"
CSV_TMP="$INSTALL_DIR/nxdn.csv.tmp"
MIN_SIZE=102400

# Gebruik --no-restart bij initiële installatie (service bestaat nog niet)
NO_RESTART=false
[[ "${1}" == "--no-restart" ]] && NO_RESTART=true

echo "[nxdnupdate] Start op $(date)"
if ! wget -q -O "$CSV_TMP" "$CSV_URL"; then
  echo "[nxdnupdate] FOUT: download mislukt"; rm -f "$CSV_TMP"; exit 1
fi
ACTUAL_SIZE=$(stat -c%s "$CSV_TMP" 2>/dev/null || echo 0)
if [[ $ACTUAL_SIZE -lt $MIN_SIZE ]]; then
  echo "[nxdnupdate] FOUT: csv te klein (${ACTUAL_SIZE} bytes)"; rm -f "$CSV_TMP"; exit 1
fi
FIRST_LINE=$(head -1 "$CSV_TMP")
if [[ "$FIRST_LINE" != *","* ]]; then
  echo "[nxdnupdate] FOUT: geen geldige CSV header"; rm -f "$CSV_TMP"; exit 1
fi
echo "[nxdnupdate] CSV geldig (${ACTUAL_SIZE} bytes)"
if [[ "$NO_RESTART" == false ]]; then
  systemctl stop nxdnreflector
fi
mv "$CSV_FILE" "$INSTALL_DIR/nxdn.old" 2>/dev/null || true
mv "$CSV_TMP" "$CSV_FILE"
chown mmdvm:mmdvm "$CSV_FILE"
chmod 644 "$CSV_FILE"
if [[ "$NO_RESTART" == false ]]; then
  systemctl start nxdnreflector
fi
echo "[nxdnupdate] Klaar op $(date)"
NXDNEOF
chmod +x $INSTALL_DIR/nxdnupdate.sh

#############################################
# SYSTEMD TIMERS
#############################################
echo ">> systemd timers aanmaken"
cat >/etc/systemd/system/nxdn-db-update.service <<EOF
[Unit]
Description=NXDN CSV dagelijkse update
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/nxdnupdate.sh
StandardOutput=append:/var/log/NXDNReflector.log
StandardError=append:/var/log/NXDNReflector-error.log
EOF

cat >/etc/systemd/system/nxdn-db-update.timer <<EOF
[Unit]
Description=NXDN CSV dagelijks om $CSV_TIME
[Timer]
OnCalendar=*-*-* ${CSV_HOUR}:${CSV_MIN}
Persistent=true
[Install]
WantedBy=timers.target
EOF

# Retry-logica in apart script (inline bash -c werkt niet in systemd unit)
cat >$INSTALL_DIR/nxdn-retry.sh <<'RETRYEOF'
#!/bin/bash
CSV="/usr/local/bin/NXDNReflector/nxdn.csv"
if [[ ! -f "$CSV" ]] || [[ $(find "$CSV" -mmin +1560 2>/dev/null | wc -l) -gt 0 ]]; then
  echo "[nxdn-retry] CSV ontbreekt of verouderd, retry gestart"
  /usr/local/bin/NXDNReflector/nxdnupdate.sh
else
  echo "[nxdn-retry] CSV actueel, geen retry nodig"
fi
RETRYEOF
chmod +x $INSTALL_DIR/nxdn-retry.sh

cat >/etc/systemd/system/nxdn-db-retry.service <<EOF
[Unit]
Description=NXDN CSV retry
After=network-online.target
Wants=network-online.target
ConditionPathExists=$INSTALL_DIR/nxdn-retry.sh
[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/nxdn-retry.sh
StandardOutput=append:/var/log/NXDNReflector.log
StandardError=append:/var/log/NXDNReflector-error.log
EOF

cat >/etc/systemd/system/nxdn-db-retry.timer <<EOF
[Unit]
Description=NXDN CSV retry elk uur
[Timer]
OnCalendar=hourly
Persistent=true
[Install]
WantedBy=timers.target
EOF

#############################################
# DASHBOARD – 1) clone GitHub  2) setup.php overschrijven
#############################################
echo ">> Dashboard clone van GitHub"
rm -rf $WWW_ROOT/NXDNReflector-Dashboard2
rm -rf /tmp/NXDNDash
git clone $DASHBOARD_REPO /tmp/NXDNDash
cd /tmp/NXDNDash
npm install
npm run build:css

mkdir -p $WWW_ROOT

if [[ "$DASH_LOCATION" == "ROOT" ]]; then
  [[ -f $WWW_ROOT/index.html ]] && mv $WWW_ROOT/index.html $WWW_ROOT/index.html.apache_backup
fi

cp -r /tmp/NXDNDash/. $WWW_ROOT/

# ── Stap 2: aangepaste setup.php plaatsen NA de clone ──────────────
echo ">> Aangepaste setup.php installeren (overschrijft GitHub versie)"
cat >$WWW_ROOT/setup.php <<'SETUPEOF'
<?php
/**
 * NXDNReflector-Dashboard2 - Setup Page
 * Copyright (C) 2025  Shane Daley, M0VUB Aka. ShaYmez
 * REMOVE THIS FILE AFTER SETUP IS COMPLETE!
 *
 * Paths pre-configured for standard install:
 *   Log files  : /var/log/
 *   Executable : /usr/local/bin/NXDNReflector/
 */

if (!defined("NXDNREFLECTORLOGPATH"))     define("NXDNREFLECTORLOGPATH",     "/var/log/");
if (!defined("NXDNREFLECTORLOGPREFIX"))   define("NXDNREFLECTORLOGPREFIX",   "NXDNReflector");
if (!defined("NXDNREFLECTORINIPATH"))     define("NXDNREFLECTORINIPATH",     "/etc/");
if (!defined("NXDNREFLECTORINIFILENAME")) define("NXDNREFLECTORINIFILENAME", "NXDNReflector.ini");
if (!defined("NXDNREFLECTORPATH"))        define("NXDNREFLECTORPATH",        "/usr/local/bin/NXDNReflector/");
if (!defined("TIMEZONE"))                 define("TIMEZONE",                 "UTC");
if (!defined("LOGO"))                     define("LOGO",                     "");
if (!defined("REFRESHAFTER"))             define("REFRESHAFTER",             "15");
if (!defined("SHOWPROGRESSBARS"))         define("SHOWPROGRESSBARS",         "");
if (!defined("SHOWOLDMHEARD"))            define("SHOWOLDMHEARD",            "7");
if (!defined("TEMPERATUREALERT"))         define("TEMPERATUREALERT",         "");
if (!defined("TEMPERATUREHIGHLEVEL"))     define("TEMPERATUREHIGHLEVEL",     "60");
if (!defined("SHOWQRZ"))                  define("SHOWQRZ",                  "");
if (!defined("GDPR"))                     define("GDPR",                     "");
if (!defined("DASHBOARD_NAME"))           define("DASHBOARD_NAME",           "NXDN Reflector Dashboard");
if (!defined("DASHBOARD_TAGLINE"))        define("DASHBOARD_TAGLINE",        "Modern Dashboard for Amateur Radio");

include "include/tools.php";
include "include/functions.php";

function createConfigLines() {
    $out = "";
    $allowedKeys = [
        "DASHBOARD_NAME"           => "string",
        "DASHBOARD_TAGLINE"        => "string",
        "LOGO"                     => "string",
        "NXDNREFLECTORLOGPATH"     => "string",
        "NXDNREFLECTORLOGPREFIX"   => "string",
        "NXDNREFLECTORINIPATH"     => "string",
        "NXDNREFLECTORINIFILENAME" => "string",
        "NXDNREFLECTORPATH"        => "string",
        "TIMEZONE"                 => "string",
        "REFRESHAFTER"             => FILTER_VALIDATE_INT,
        "SHOWOLDMHEARD"            => FILTER_VALIDATE_INT,
        "TEMPERATUREHIGHLEVEL"     => FILTER_VALIDATE_INT,
        "SHOWPROGRESSBARS"         => "string",
        "TEMPERATUREALERT"         => "string",
        "SHOWQRZ"                  => "string",
        "GDPR"                     => "string"
    ];
    foreach ($_GET as $key => $val) {
        if ($key != "cmd" && isset($allowedKeys[$key])) {
            if ($allowedKeys[$key] === FILTER_VALIDATE_INT) {
                $sanitizedVal = filter_var($val, FILTER_VALIDATE_INT);
                if ($sanitizedVal === false) continue;
            } else {
                $sanitizedVal = htmlspecialchars($val, ENT_QUOTES | ENT_HTML5, 'UTF-8');
            }
            if ($val === "on") {
                $out .= "define(\"" . addslashes($key) . "\", true);\n";
            } else {
                $out .= "define(\"" . addslashes($key) . "\", \"" . addslashes($sanitizedVal) . "\");\n";
            }
        }
    }
    return $out;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NXDNReflector-Dashboard2 - Setup</title>
    <link rel="stylesheet" href="assets/css/output.css">
    <style>.setup-bg { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }</style>
</head>
<body class="setup-bg">
<?php
if (isset($_GET['cmd']) && $_GET['cmd'] == "writeconfig") {
    if (!file_exists('./config')) {
        if (!mkdir('./config', 0755, true)) { ?>
    <div class="container mx-auto px-4 py-12"><div class="max-w-2xl mx-auto">
        <div class="bg-red-500/20 border border-red-500 rounded-xl p-6">
            <p class="text-lg">You forgot to give write permissions to your webserver user!</p>
        </div>
    </div></div>
    <?php }
    }
    $configfile = fopen("config/config.php", 'w');
    fwrite($configfile, "<?php\n/**\n * NXDNReflector-Dashboard2 Configuration\n * Auto-generated\n */\n\ndate_default_timezone_set('UTC');\n\n");
    fwrite($configfile, createConfigLines());
    fwrite($configfile, "?>\n");
    fclose($configfile);
?>
    <div class="container mx-auto px-4 py-12"><div class="max-w-2xl mx-auto">
        <div class="card-glossy p-8 text-center">
            <svg class="w-20 h-20 mx-auto text-green-500 mb-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <h1 class="text-3xl font-bold mb-4">Setup Complete!</h1>
            <p class="text-lg mb-6 text-white/80">Configuration saved to config/config.php</p>
            <div class="bg-yellow-500/20 border border-yellow-500 rounded-xl p-4 mb-6">
                <p class="font-semibold">&#9888; Security Notice</p>
                <p class="text-sm mt-2">Remove setup.php from your web directory after setup!</p>
            </div>
            <a href="index.php" class="btn-primary inline-block">Go to Dashboard &rarr;</a>
        </div>
    </div></div>
<?php } else { ?>
    <div class="container mx-auto px-4 py-12">
        <div class="max-w-5xl mx-auto">
            <div class="text-center mb-12">
                <h1 class="text-5xl font-bold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-blue-200 to-purple-200">
                    NXDNReflector-Dashboard2
                </h1>
                <p class="text-xl text-white/80">Initial Setup &amp; Configuration</p>
            </div>

            <form id="config" action="setup.php" method="get" class="space-y-8">
                <input type="hidden" name="cmd" value="writeconfig">

                <!-- Branding -->
                <div class="card-glossy p-8">
                    <h2 class="text-3xl font-bold mb-6 flex items-center">
                        <svg class="w-8 h-8 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"></path>
                        </svg>
                        Dashboard Branding
                    </h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label class="block text-sm font-semibold mb-2">Dashboard Name</label>
                            <input type="text" name="DASHBOARD_NAME" value="<?php echo constant("DASHBOARD_NAME") ?>"
                                   class="input-glossy w-full" placeholder="NXDN Reflector Dashboard" required>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">Dashboard Tagline</label>
                            <input type="text" name="DASHBOARD_TAGLINE" value="<?php echo constant("DASHBOARD_TAGLINE") ?>"
                                   class="input-glossy w-full" placeholder="Modern Dashboard for Amateur Radio">
                        </div>
                        <div class="md:col-span-2">
                            <label class="block text-sm font-semibold mb-2">Logo URL or Local Path (optional)</label>
                            <input type="text" name="LOGO" value="<?php echo constant("LOGO") ?>"
                                   class="input-glossy w-full" placeholder="https://example.com/logo.png or img/logo.png">
                            <p class="text-sm text-white/60 mt-2">
                                Place your logo in the <code class="bg-white/10 px-2 py-1 rounded">img/</code> directory or enter a full URL.<br>
                                <strong>Supported formats:</strong> <?php echo htmlspecialchars(getLogoFormatsDisplay(), ENT_QUOTES, 'UTF-8'); ?>
                            </p>
                        </div>
                    </div>
                </div>

                <!-- NXDNReflector Configuration -->
                <div class="card-glossy p-8">
                    <h2 class="text-3xl font-bold mb-6 flex items-center">
                        <svg class="w-8 h-8 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                        </svg>
                        NXDNReflector Configuration
                    </h2>
                    <div class="space-y-6">
                        <div>
                            <label class="block text-sm font-semibold mb-2">Path to NXDNReflector Log Files</label>
                            <input type="text" name="NXDNREFLECTORLOGPATH" value="<?php echo constant("NXDNREFLECTORLOGPATH") ?>"
                                   class="input-glossy w-full" placeholder="/var/log/" required>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">Log File Prefix</label>
                            <input type="text" name="NXDNREFLECTORLOGPREFIX" value="<?php echo constant("NXDNREFLECTORLOGPREFIX") ?>"
                                   class="input-glossy w-full" placeholder="NXDNReflector" required>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">Path to NXDNReflector.ini</label>
                            <input type="text" name="NXDNREFLECTORINIPATH" value="<?php echo constant("NXDNREFLECTORINIPATH") ?>"
                                   class="input-glossy w-full" placeholder="/etc/" required>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">NXDNReflector.ini Filename</label>
                            <input type="text" name="NXDNREFLECTORINIFILENAME" value="<?php echo constant("NXDNREFLECTORINIFILENAME") ?>"
                                   class="input-glossy w-full" placeholder="NXDNReflector.ini" required>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">Path to NXDNReflector Executable</label>
                            <input type="text" name="NXDNREFLECTORPATH" value="<?php echo constant("NXDNREFLECTORPATH") ?>"
                                   class="input-glossy w-full" placeholder="/usr/local/bin/NXDNReflector/" required>
                        </div>
                    </div>
                </div>

                <!-- Global Settings -->
                <div class="card-glossy p-8">
                    <h2 class="text-3xl font-bold mb-6 flex items-center">
                        <svg class="w-8 h-8 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path>
                        </svg>
                        Global Settings
                    </h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label class="block text-sm font-semibold mb-2">Timezone</label>
                            <select name="TIMEZONE" class="input-glossy w-full">
                                <?php
                                $timezones = timezone_identifiers_list();
                                $current_tz = constant("TIMEZONE");
                                foreach ($timezones as $tz) {
                                    $selected = ($tz === $current_tz) ? 'selected' : '';
                                    echo "<option value=\"" . htmlspecialchars($tz, ENT_QUOTES, 'UTF-8') . "\" $selected>" . htmlspecialchars($tz, ENT_QUOTES, 'UTF-8') . "</option>";
                                }
                                ?>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">Refresh Interval (seconds)</label>
                            <input type="number" name="REFRESHAFTER" value="<?php echo constant("REFRESHAFTER") ?>"
                                   class="input-glossy w-full" placeholder="15" required>
                            <p class="text-xs text-white/60 mt-1">Default: 15 seconds. Lower values provide more responsive updates.</p>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">Historic Logs (days)</label>
                            <input type="number" name="SHOWOLDMHEARD" value="<?php echo constant("SHOWOLDMHEARD") ?>"
                                   class="input-glossy w-full" placeholder="7" required>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">Temperature Warning Level (&deg;C)</label>
                            <input type="number" name="TEMPERATUREHIGHLEVEL" value="<?php echo constant("TEMPERATUREHIGHLEVEL") ?>"
                                   class="input-glossy w-full" placeholder="60" required>
                        </div>
                    </div>
                    <div class="mt-8 space-y-4">
                        <label class="flex items-center space-x-3 cursor-pointer">
                            <input type="checkbox" name="SHOWPROGRESSBARS" class="w-5 h-5 rounded" <?php if (defined("SHOWPROGRESSBARS") && constant("SHOWPROGRESSBARS")) echo "checked" ?>>
                            <span class="text-sm font-medium">Show Progress Bars</span>
                        </label>
                        <label class="flex items-center space-x-3 cursor-pointer">
                            <input type="checkbox" name="TEMPERATUREALERT" class="w-5 h-5 rounded" <?php if (defined("TEMPERATUREALERT") && constant("TEMPERATUREALERT")) echo "checked" ?>>
                            <span class="text-sm font-medium">Enable CPU Temperature Warnings</span>
                        </label>
                        <label class="flex items-center space-x-3 cursor-pointer">
                            <input type="checkbox" name="SHOWQRZ" class="w-5 h-5 rounded" <?php if (defined("SHOWQRZ") && constant("SHOWQRZ")) echo "checked" ?>>
                            <span class="text-sm font-medium">Show QRZ.com Links on Callsigns</span>
                        </label>
                        <label class="flex items-center space-x-3 cursor-pointer">
                            <input type="checkbox" name="GDPR" class="w-5 h-5 rounded" <?php if (defined("GDPR") && constant("GDPR")) echo "checked" ?>>
                            <span class="text-sm font-medium">Anonymize Callsigns (GDPR Compliance)</span>
                        </label>
                    </div>
                </div>

                <!-- Submit -->
                <div class="text-center">
                    <button type="submit" class="btn-primary text-lg px-12 py-4">
                        <span class="flex items-center justify-center">
                            <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                            </svg>
                            Save Configuration
                        </span>
                    </button>
                </div>
            </form>

            <div class="text-center mt-12 text-white/60 text-sm">
                <p>NXDNReflector-Dashboard2 by ShaYmez &mdash; Compatible with NXDNReflector</p>
            </div>
        </div>
    </div>
<?php } ?>
</body>
</html>
SETUPEOF

echo ">> setup.php geplaatst met correcte standaardpaden"

echo ">> Aangepaste index.php installeren (overschrijft GitHub versie)"
cat >$WWW_ROOT/index.php <<'INDEXEOF'
<?php
/**
 * NXDNReflector-Dashboard2 by M0VUB Aka ShaYmez - Main Dashboard
 * Responsive dashboard for NXDNReflector (G4KLX)
 * Copyright (C) 2025  Shane Daley, M0VUB Aka. ShaYmez
 */

$time = microtime();
$time = explode(' ', $time);
$time = $time[1] + $time[0];
$start = $time;

// Check if config exists
if (!file_exists("config/config.php")) {
    header("Location: setup.php");
    exit();
}

// Load configuration and includes
include "config/config.php";
include "include/tools.php";
include "include/functions.php";

// Initialize data
$configs = getNXDNReflectorConfig();
if (!defined("TIMEZONE")) {
    define("TIMEZONE", "UTC");
}

$logLines = getNXDNReflectorLog();

$reverseLogLines = $logLines;
array_multisort($reverseLogLines, SORT_DESC);
$lastHeard = getLastHeard($reverseLogLines);

$repeaters = getLinkedRepeaters($logLines);
$currentlyTXing = getCurrentlyTXing($logLines);
$sysInfo = getSystemInfo();
$diskInfo = getDiskInfo();

// Version info
define("VERSION", "2.0.1");
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="NXDNReflector-Dashboard V2">
    <meta name="author" content="M0VUB Aka ShaYmez">
    <meta http-equiv="expires" content="0">
    
    <title><?php echo htmlspecialchars(defined("DASHBOARD_NAME") ? DASHBOARD_NAME : "NXDN Reflector Dashboard", ENT_QUOTES, 'UTF-8'); ?> - <?php $tg = getConfigItem("General", "TG", $configs); echo !empty($tg) ? "TG ".$tg : "NXDN"; ?></title>
    
    <link rel="stylesheet" href="assets/css/output.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>
    <!-- Animated Background -->
    <div class="fixed inset-0 -z-10 overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900"></div>
        <div class="absolute top-0 left-0 w-full h-full opacity-20">
            <div class="absolute top-20 left-20 w-96 h-96 bg-blue-500 rounded-full filter blur-3xl animate-pulse"></div>
            <div class="absolute bottom-20 right-20 w-96 h-96 bg-purple-500 rounded-full filter blur-3xl animate-pulse" style="animation-delay: 1s;"></div>
        </div>
    </div>

    <div class="container mx-auto px-4 py-8">
        <?php checkSetup(); ?>

        <!-- Header -->
        <div class="card-glossy p-6 mb-8">
            <div class="flex flex-col lg:flex-row items-center justify-between">
                <div class="flex-1">
                    <h1 class="text-4xl font-bold mb-2 bg-clip-text text-transparent bg-gradient-to-r from-blue-200 to-purple-200">
                        <?php echo htmlspecialchars(defined("DASHBOARD_NAME") ? DASHBOARD_NAME : "NXDN Reflector Dashboard", ENT_QUOTES, 'UTF-8'); ?>
                    </h1>
                    <p class="text-lg text-white/80">
                        <?php echo htmlspecialchars(defined("DASHBOARD_TAGLINE") ? DASHBOARD_TAGLINE : "Modern Dashboard for Amateur Radio", ENT_QUOTES, 'UTF-8'); ?>
                    </p>
                    <div class="mt-4 flex flex-wrap gap-4 text-sm">
                        <div class="flex items-center">
                            <svg class="w-5 h-5 mr-2 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                            </svg>
                            <span>Talk Group: <strong>TG <?php echo htmlspecialchars(getConfigItem("General", "TG", $configs), ENT_QUOTES, 'UTF-8'); ?></strong></span>
                        </div>
                    </div>
                </div>
                <?php 
                $logoPath = getLogoPath();
                if ($logoPath !== false) { 
                ?>
                <div class="mt-6 lg:mt-0">
                    <img src="<?php echo htmlspecialchars($logoPath, ENT_QUOTES, 'UTF-8'); ?>" 
                         alt="Logo" 
                         class="max-w-xs h-32 object-contain rounded-xl shadow-glossy">
                </div>
                <?php } ?>
            </div>
        </div>

        <!-- Currently TXing Alert -->
        <?php if ($currentlyTXing !== null) { ?>
        <div id="tx-alert" class="card-glossy p-6 mb-8 border-2 border-red-500/50 animate-pulse">
            <div class="flex items-center">
                <div class="bg-red-500/30 p-4 rounded-xl mr-6">
                    <svg class="w-12 h-12 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"></path>
                    </svg>
                </div>
                <div class="flex-1">
                    <div class="flex items-center mb-2">
                        <span class="inline-block w-3 h-3 bg-red-500 rounded-full mr-3 animate-pulse"></span>
                        <h2 class="text-3xl font-bold text-red-400">TRANSMITTING...</h2>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                        <div>
                            <p class="text-white/60 text-sm uppercase tracking-wide">Callsign</p>
                            <p id="tx-callsign" class="text-2xl font-bold text-white mt-1">
                                <?php 
                                if (defined("SHOWQRZ") && SHOWQRZ && $currentlyTXing['source'] !== "??????????" && !is_numeric($currentlyTXing['source'])) {
                                    echo '<a target="_blank" href="https://qrz.com/db/'.htmlspecialchars($currentlyTXing['source'], ENT_QUOTES, 'UTF-8').'" class="text-blue-300 hover:text-blue-200 underline">'.htmlspecialchars(str_replace("0","Ø",$currentlyTXing['source']), ENT_QUOTES, 'UTF-8').'</a>';
                                } else if (defined("GDPR") && GDPR) {
                                    echo htmlspecialchars(str_replace("0","Ø",substr($currentlyTXing['source'],0,3)."***"), ENT_QUOTES, 'UTF-8');
                                } else {
                                    echo htmlspecialchars(str_replace("0","Ø",$currentlyTXing['source']), ENT_QUOTES, 'UTF-8');
                                }
                                ?>
                            </p>
                        </div>
                        <div>
                            <p class="text-white/60 text-sm uppercase tracking-wide">Target</p>
                            <p id="tx-target" class="text-2xl font-bold text-white mt-1"><?php echo htmlspecialchars($currentlyTXing['target'], ENT_QUOTES, 'UTF-8'); ?></p>
                        </div>
                        <div>
                            <p class="text-white/60 text-sm uppercase tracking-wide">Via Repeater</p>
                            <p id="tx-repeater" class="text-2xl font-bold text-white mt-1">
                                <?php 
                                if (defined("GDPR") && GDPR) {
                                    echo htmlspecialchars(str_replace("0","Ø",substr($currentlyTXing['gateway'],0,3)."***"), ENT_QUOTES, 'UTF-8');
                                } else {
                                    echo htmlspecialchars(str_replace("0","Ø",$currentlyTXing['gateway']), ENT_QUOTES, 'UTF-8');
                                }
                                ?>
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <?php } ?>

        <!-- System Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <!-- Connected Repeaters -->
            <div class="card-glossy p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-white/60 text-sm font-semibold uppercase tracking-wide">Connected</p>
                        <p id="repeater-count" class="text-4xl font-bold mt-2"><?php echo count($repeaters); ?></p>
                        <p class="text-sm text-white/80 mt-1">Repeaters</p>
                    </div>
                    <div class="bg-blue-500/20 p-4 rounded-xl">
                        <svg class="w-10 h-10 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                        </svg>
                    </div>
                </div>
            </div>

            <!-- CPU Load -->
            <div class="card-glossy p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-white/60 text-sm font-semibold uppercase tracking-wide">CPU Load</p>
                        <p class="text-4xl font-bold mt-2"><?php echo number_format($sysInfo['load'][0], 2); ?></p>
                        <p class="text-sm text-white/80 mt-1">Average (1m)</p>
                    </div>
                    <div class="bg-green-500/20 p-4 rounded-xl">
                        <svg class="w-10 h-10 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"></path>
                        </svg>
                    </div>
                </div>
            </div>

            <!-- Temperature -->
            <div class="card-glossy p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-white/60 text-sm font-semibold uppercase tracking-wide">Temperature</p>
                        <p class="text-4xl font-bold mt-2 <?php echo (defined('TEMPERATUREALERT') && $sysInfo['temperature'] > TEMPERATUREHIGHLEVEL) ? 'text-red-500' : ''; ?>"><?php echo $sysInfo['temperature']; ?>°C</p>
                        <p class="text-sm text-white/80 mt-1">CPU Temp</p>
                    </div>
                    <div class="bg-orange-500/20 p-4 rounded-xl">
                        <svg class="w-10 h-10 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                        </svg>
                    </div>
                </div>
            </div>

            <!-- Disk Usage -->
            <div class="card-glossy p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-white/60 text-sm font-semibold uppercase tracking-wide">Disk Usage</p>
                        <p class="text-4xl font-bold mt-2"><?php echo $diskInfo['percent']; ?>%</p>
                        <p class="text-sm text-white/80 mt-1"><?php echo $diskInfo['used']; ?> / <?php echo $diskInfo['total']; ?> GB</p>
                    </div>
                    <div class="bg-purple-500/20 p-4 rounded-xl">
                        <svg class="w-10 h-10 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"></path>
                        </svg>
                    </div>
                </div>
            </div>
        </div>

        <!-- Last Heard + Connected Repeaters naast elkaar -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">

            <!-- Last Heard List -->
            <div class="card-glossy p-6">
                <h2 class="text-2xl font-bold mb-6 flex items-center">
                    <svg class="w-6 h-6 mr-3 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"></path>
                    </svg>
                    Last Heard List
                </h2>
                <div class="overflow-x-auto">
                    <table class="table-glossy">
                        <thead>
                            <tr>
                                <th>Time (<?php echo TIMEZONE;?>)</th>
                                <th>Callsign</th>
                                <th>Target</th>
                                <th>Repeater</th>
                            </tr>
                        </thead>
                        <tbody id="last-heard-table-body">
                            <?php
                            if (count($lastHeard) > 0) {
                                foreach ($lastHeard as $heard) {
                                    echo "<tr>";
                                    echo "<td>".htmlspecialchars($heard[0], ENT_QUOTES, 'UTF-8')."</td>";
                                    
                                    // Callsign with QRZ link if enabled
                                    if (defined("SHOWQRZ") && SHOWQRZ && $heard[1] !== "??????????" && !is_numeric($heard[1])) {
                                        echo "<td><a target=\"_blank\" href=\"https://qrz.com/db/".htmlspecialchars($heard[1], ENT_QUOTES, 'UTF-8')."\" class=\"text-blue-400 hover:text-blue-300 underline\">".htmlspecialchars(str_replace("0","Ø",$heard[1]), ENT_QUOTES, 'UTF-8')."</a></td>";
                                    } else {
                                        if (defined("GDPR") && GDPR) {
                                            echo "<td>".htmlspecialchars(str_replace("0","Ø",substr($heard[1],0,3)."***"), ENT_QUOTES, 'UTF-8')."</td>";
                                        } else {
                                            echo "<td>".htmlspecialchars(str_replace("0","Ø",$heard[1]), ENT_QUOTES, 'UTF-8')."</td>";
                                        }
                                    }
                                    
                                    echo "<td>".htmlspecialchars($heard[2], ENT_QUOTES, 'UTF-8')."</td>";
                                    
                                    // Repeater callsign
                                    if (defined("GDPR") && GDPR) {
                                        echo "<td>".htmlspecialchars(str_replace("0","Ø",substr($heard[3],0,3)."***"), ENT_QUOTES, 'UTF-8')."</td>";
                                    } else {
                                        echo "<td>".htmlspecialchars(str_replace("0","Ø",$heard[3]), ENT_QUOTES, 'UTF-8')."</td>";
                                    }
                                    
                                    echo "</tr>";
                                }
                            } else {
                                echo "<tr><td colspan='4' class='text-center text-white/60'>No activity recorded</td></tr>";
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Connected Repeaters -->
            <div class="card-glossy p-6">
                <h2 class="text-2xl font-bold mb-6 flex items-center">
                    <svg class="w-6 h-6 mr-3 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"></path>
                    </svg>
                    Connected Repeaters
                </h2>
                <div class="overflow-x-auto">
                    <table class="table-glossy">
                        <thead>
                            <tr>
                                <th>Time (<?php echo TIMEZONE;?>)</th>
                                <th>Callsign</th>
                            </tr>
                        </thead>
                        <tbody id="repeaters-table-body">
                            <?php
                            if (count($repeaters) > 0) {
                                foreach ($repeaters as $repeater) {
                                    echo "<tr>";
                                    echo "<td>".htmlspecialchars(convertTimezone($repeater['timestamp']), ENT_QUOTES, 'UTF-8')."</td>";
                                    if (defined("GDPR") && GDPR) {
                                        echo "<td>".htmlspecialchars(str_replace("0","Ø",substr($repeater['callsign'],0,3)."***"), ENT_QUOTES, 'UTF-8')."</td>";
                                    } else {
                                        echo "<td>".htmlspecialchars(str_replace("0","Ø",$repeater['callsign']), ENT_QUOTES, 'UTF-8')."</td>";
                                    }
                                    echo "</tr>";
                                }
                            } else {
                                echo "<tr><td colspan='2' class='text-center text-white/60'>No repeaters connected</td></tr>";
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>

        </div>

        <!-- System Information (volle breedte) -->
        <div class="card-glossy p-6 mb-8">
            <h2 class="text-2xl font-bold mb-6 flex items-center">
                <svg class="w-6 h-6 mr-3 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"></path>
                </svg>
                System Information
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-x-12 gap-y-0">
                <div class="flex justify-between items-center py-3 border-b border-white/10">
                    <span class="text-white/80">System Uptime</span>
                    <span class="font-semibold"><?php echo $sysInfo['uptime']; ?></span>
                </div>
                <div class="flex justify-between items-center py-3 border-b border-white/10">
                    <span class="text-white/80">Load Average (1m)</span>
                    <span class="font-semibold"><?php echo number_format($sysInfo['load'][0], 2); ?></span>
                </div>
                <div class="flex justify-between items-center py-3 border-b border-white/10">
                    <span class="text-white/80">Load Average (5m)</span>
                    <span class="font-semibold"><?php echo number_format($sysInfo['load'][1], 2); ?></span>
                </div>
                <div class="flex justify-between items-center py-3 border-b border-white/10">
                    <span class="text-white/80">Load Average (15m)</span>
                    <span class="font-semibold"><?php echo number_format($sysInfo['load'][2], 2); ?></span>
                </div>
                <div class="flex justify-between items-center py-3 border-b border-white/10">
                    <span class="text-white/80">NXDNReflector Version</span>
                    <span class="font-semibold text-sm"><?php echo getNXDNReflectorVersion(); ?></span>
                </div>
                <div class="flex justify-between items-center py-3 border-b border-white/10">
                    <span class="text-white/80">Dashboard Version</span>
                    <span class="font-semibold"><?php echo VERSION; ?></span>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <div class="card-glossy p-6 text-center">
            <div class="text-sm text-white/80">
                <?php
                $lastReload = new DateTime();
                $lastReload->setTimezone(new DateTimeZone(TIMEZONE));
                echo "NXDNReflector-Dashboard2 V".VERSION." | Last Reload ".$lastReload->format('Y-m-d, H:i:s')." (".TIMEZONE.")";
                $time = microtime();
                $time = explode(' ', $time);
                $time = $time[1] + $time[0];
                $finish = $time;
                $total_time = round(($finish - $start), 4);
                echo ' | Page generated in '.$total_time.' seconds';
                ?>
            </div>
            <div class="mt-3">
                <a href="https://github.com/ShaYmez/NXDNReflector-Dashboard2" target="_blank" class="text-blue-400 hover:text-blue-300 underline text-sm">
                    Get your own at GitHub
                </a>
            </div>
        </div>
    </div>
    
    <!-- JavaScript for full dashboard live updates -->
    <script>
        // Update dashboard every 5 seconds for fully responsive, real-time updates
        let lastTxState = <?php echo $currentlyTXing !== null ? 'true' : 'false'; ?>;
        let lastTxCallsign = <?php echo $currentlyTXing !== null ? '"' . addslashes($currentlyTXing['source']) . '"' : 'null'; ?>;
        
        function updateDashboard() {
            fetch('api/dashboard_data.php')
                .then(response => response.json())
                .then(data => {
                    if (!data.success) {
                        console.error('Dashboard update failed:', data.error);
                        return;
                    }
                    
                    // Update TX Status
                    updateTxStatus(data.tx_status);
                    
                    // Update Repeater Count
                    const repeaterCountEl = document.getElementById('repeater-count');
                    if (repeaterCountEl) {
                        repeaterCountEl.textContent = data.repeater_count;
                    }
                    
                    // Update Repeaters Table
                    updateRepeatersTable(data.repeaters);
                    
                    // Update Last Heard Table
                    updateLastHeardTable(data.last_heard);
                })
                .catch(error => {
                    console.error('Error fetching dashboard data:', error);
                });
        }
        
        function updateTxStatus(txData) {
            const txAlert = document.getElementById('tx-alert');
            
            if (txData && txData.is_transmitting) {
                // Transmission is active
                if (!lastTxState) {
                    // New transmission started - show alert
                    if (txAlert) {
                        txAlert.style.display = 'block';
                        txAlert.classList.add('animate-pulse');
                    } else {
                        // TX alert doesn't exist, create it dynamically
                        createTxAlert(txData);
                    }
                } else {
                    // Update existing TX display
                    updateTxDisplay(txData);
                }
                lastTxState = true;
                lastTxCallsign = txData.source;
            } else {
                // No transmission
                if (lastTxState && txAlert) {
                    // Transmission ended - hide alert
                    txAlert.style.display = 'none';
                }
                lastTxState = false;
                lastTxCallsign = null;
            }
        }
        
        function createTxAlert(data) {
            // Create TX alert element dynamically if it doesn't exist
            const container = document.querySelector('.container');
            const statsGrid = document.querySelector('.grid.grid-cols-1.md\\:grid-cols-2');
            
            if (!container || !statsGrid) return;
            
            const txAlertHTML = `
                <div id="tx-alert" class="card-glossy p-6 mb-8 border-2 border-red-500/50 animate-pulse">
                    <div class="flex items-center">
                        <div class="bg-red-500/30 p-4 rounded-xl mr-6">
                            <svg class="w-12 h-12 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"></path>
                            </svg>
                        </div>
                        <div class="flex-1">
                            <div class="flex items-center mb-2">
                                <span class="inline-block w-3 h-3 bg-red-500 rounded-full mr-3 animate-pulse"></span>
                                <h2 class="text-3xl font-bold text-red-400">TRANSMITTING...</h2>
                            </div>
                            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                                <div>
                                    <p class="text-white/60 text-sm uppercase tracking-wide">Callsign</p>
                                    <p id="tx-callsign" class="text-2xl font-bold text-white mt-1"></p>
                                </div>
                                <div>
                                    <p class="text-white/60 text-sm uppercase tracking-wide">Target</p>
                                    <p id="tx-target" class="text-2xl font-bold text-white mt-1"></p>
                                </div>
                                <div>
                                    <p class="text-white/60 text-sm uppercase tracking-wide">Via Repeater</p>
                                    <p id="tx-repeater" class="text-2xl font-bold text-white mt-1"></p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            
            statsGrid.insertAdjacentHTML('beforebegin', txAlertHTML);
            updateTxDisplay(data);
        }
        
        function updateTxDisplay(data) {
            const callsignEl = document.getElementById('tx-callsign');
            if (callsignEl) {
                if (data.qrz_link) {
                    callsignEl.innerHTML = '<a target="_blank" href="' + data.qrz_link + '" class="text-blue-300 hover:text-blue-200 underline">' + data.source_display + '</a>';
                } else {
                    callsignEl.textContent = data.source_display;
                }
            }
            
            const targetEl = document.getElementById('tx-target');
            if (targetEl) {
                targetEl.textContent = data.target;
            }
            
            const repeaterEl = document.getElementById('tx-repeater');
            if (repeaterEl) {
                repeaterEl.textContent = data.repeater_display;
            }
        }
        
        function updateRepeatersTable(repeaters) {
            const tbody = document.getElementById('repeaters-table-body');
            if (!tbody) return;
            
            if (repeaters.length === 0) {
                tbody.innerHTML = '<tr><td colspan="2" class="text-center text-white/60">No repeaters connected</td></tr>';
                return;
            }
            
            let html = '';
            repeaters.forEach(repeater => {
                html += '<tr>';
                html += '<td>' + repeater.timestamp + '</td>';
                html += '<td>' + repeater.callsign_display + '</td>';
                html += '</tr>';
            });
            tbody.innerHTML = html;
        }
        
        function updateLastHeardTable(lastHeard) {
            const tbody = document.getElementById('last-heard-table-body');
            if (!tbody) return;
            
            if (lastHeard.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4" class="text-center text-white/60">No activity recorded</td></tr>';
                return;
            }
            
            let html = '';
            lastHeard.forEach(heard => {
                html += '<tr>';
                html += '<td>' + heard.time + '</td>';
                
                // Callsign with optional QRZ link
                if (heard.qrz_link) {
                    html += '<td><a target="_blank" href="' + heard.qrz_link + '" class="text-blue-400 hover:text-blue-300 underline">' + heard.callsign_display + '</a></td>';
                } else {
                    html += '<td>' + heard.callsign_display + '</td>';
                }
                
                html += '<td>' + heard.target + '</td>';
                html += '<td>' + heard.repeater_display + '</td>';
                html += '</tr>';
            });
            tbody.innerHTML = html;
        }
        
        // Start updating dashboard every 5 seconds for full real-time experience
        setInterval(updateDashboard, 250);
    </script>
</body>
</html>
INDEXEOF

echo ">> index.php geplaatst (Last Heard + Connected Repeaters naast elkaar, refresh 250ms)"


#############################################
# DASHBOARD CONFIG.PHP
#############################################
echo ">> Dashboard config.php aanmaken"
mkdir -p $WWW_ROOT/config
cat >$WWW_ROOT/config/config.php <<EOF
<?php
date_default_timezone_set('${TIMEZONE}');

define('DASHBOARD_NAME',    '${REFLECTOR_NAME}');
define('DASHBOARD_TAGLINE', 'Modern Dashboard for Amateur Radio');
define('TIMEZONE',          '${TIMEZONE}');

\$reflectorName = "${REFLECTOR_NAME}";
\$serviceName   = "nxdnreflector";

\$logPath      = "/var/log/NXDNReflector.log";
\$errorLogPath = "/var/log/NXDNReflector-error.log";
\$nxdnCSV      = "/usr/local/bin/NXDNReflector/nxdn.csv";
\$iniFile      = "/etc/NXDNReflector.ini";

\$refresh = ${DASH_REFRESH};
\$debug   = false;
EOF

chown -R www-data:www-data $WWW_ROOT
chmod 640 $WWW_ROOT/config/config.php

#############################################
# INITIËLE CSV DOWNLOAD
#############################################
#############################################
# SERVICES ACTIVEREN
#############################################
echo ">> Services activeren"
systemctl daemon-reload
systemctl enable nxdnreflector

echo ">> Initiële NXDN CSV downloaden"
bash $INSTALL_DIR/nxdnupdate.sh --no-restart || {
  echo ">> WAARSCHUWING: initiële CSV download mislukt, retry timer actief"
}

systemctl start nxdnreflector
systemctl enable --now nxdn-db-update.timer
systemctl enable --now nxdn-db-retry.timer
systemctl restart apache2

#############################################
# EINDSCHERM
#############################################
IP=$(hostname -I | awk '{print $1}')

if [[ "$DASH_LOCATION" == "ROOT" ]]; then
  DASH_URL="http://${IP}/"
  SETUP_REAL_URL="http://${IP}/setup.php"
else
  DASH_URL="http://${IP}/${DASH_SUBDIR}/"
  SETUP_REAL_URL="http://${IP}/${DASH_SUBDIR}/setup.php"
fi

whiptail --title "$T_DONE_TITLE" --msgbox \
"$T_DONE_HEAD

  Reflector : TG $NEWTG  |  UDP $NEWPORT
  Dashboard : $DASH_URL
  CSV       : $T_DONE_DAILY $CSV_TIME

  ================================================
  $T_DONE_SETUP_HEAD
  --> $SETUP_REAL_URL
  $T_DONE_SETUP_WARN
  ================================================

  $T_DONE_CMDS:
    systemctl status nxdnreflector
    nano /etc/NXDNReflector.ini
    tail -f /var/log/NXDNReflector.log

  $T_DONE_AFTER:
    systemctl restart nxdnreflector" \
  30 68

echo ""
echo "=== DONE ==="
echo "  Dashboard : $DASH_URL"
echo "  Setup.php : $SETUP_REAL_URL"
echo ""
