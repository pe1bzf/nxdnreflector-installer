One-step NXDNReflector installer for Raspberry Pi OS

Based on the repository DVReflector from nostar

Made with a lot of help from Claude.ai ;-)


Install a 64 bit lite version of the raspberry OS 

user mmdvm

copy install_nxdnreflector.sh into home directory

(or use: git clone https://github.com/pe1bzf/install_nxdnreflector.git)

        sudo chmod +x install_nxdn_all_in_one.sh
        sudo bash install_nxdnreflector.sh

   Watch the show en enjoy.

Interactive-menu
Also, if chosen, icecast for live listening nxdn transmissions on your reflector
Post install: (script polished for maximum convenience)
dont forget to run the setup.php from the homepage of the dashboard

follow instructions on screen.

enable via DVref.com 

Read https://dvref.com/docs/getting-started/


That's all folks

additional info:
script contains

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
        
        
        
