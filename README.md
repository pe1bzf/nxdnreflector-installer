One-step NXDNReflector installer for Raspberry Pi OS
Also tested on Debian 13, Other Linux flavor not tested

Based on the repository DVReflector from nostar
and Icecast for live decoded audio with DSD

Made with a lot of help from Claude.ai ;-)

Install a 64 bit lite version of the raspberry OS, 
user mmdvm,
copy install_nxdnreflector.sh into home directory

(or use: git clone https://github.com/pe1bzf/install_nxdnreflector.git)

        sudo chmod +x install_nxdnreflector.sh
        sudo bash install_nxdnreflector.sh

   Watch the show en enjoy.

Interactive-menu made on Whiptail.

if chosen, icecast for live listening nxdn transmissions on your reflector

Post install:
dont forget to run the setup.php from the homepage of the dashboard
to finish the dashboard install.

follow instructions on screen.

Registrate and enable your reflector via DVref.com and Radioid.com  for visability for Hamradio amateurs
Read instructions on https://dvref.com/docs/getting-started/

That's all folks

additional info:
script contains:

        update and upgrade
        install apache2, php, git, build essentials and more (see script for details)
        config ufw firewall
        git clone repro NXDNReflector from github
        config reflector, log-files and proper rights to read log-file
        create systemd services for auto start and more
        configure logrotate
        install icecast
        nxdn user database update daily at 05:30 from radioid.net and check for update every hour
        install NXDNReflector-Dashboard2 from ShaYmez 
        
        
        
