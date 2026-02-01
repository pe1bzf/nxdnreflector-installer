One-step NXDNReflector installer for Raspberry Pi OS

Based on the repository DVReflector from nostar

Made with a lot of help from chatGPT ;-)


Install a lite version of the raspberry OS (full version will also work, bud with overhead)

user mmdvm

copy install_nxdn_all_in_one.sh into home directory

        sudo chmod +x install_nxdn_all_in_one.sh
        sudo dos2unix install_nxdn_all_in_one.sh (if necessary)
        sudo bash install_nxdn_all_in_one.sh

   Watch the show en enjoy.

Post install: (script polished for maximum convenience)

follow instructions on screen

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
        nxdn user database update daily at 05:30 from radioid.net
        install NXDNReflector-Dashboard2 from ShaYmez 
        
        
        
