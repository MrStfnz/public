#!/bin/bash
#       _    __           
#   ___| |_ / _|_ __  ____
#  / __| __| |_| '_ \|_  /
#  \__ \ |_|  _| | | |/ / 
#  |___/\__|_| |_| |_/___|

# update added ipmievd.service, as sometimes debian is a b#tch

# Let me check the distro?
if [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
        echo "Debian / Ubuntu found, so using apt-get for installing the correct tools"
        apt-get install ipmitool openipmi -y

#in case of redhat
elif [ -f /etc/redhat-release ]; then
        echo "RHEL / CentOS found, so using yum for installing the correct tools"
        yum install OpenIPMI ipmitool -y

# if none of these are found, you're on your own..
else
        echo "I don't know what you are running for distro. Custom? Install 'ipmitool' and/or 'OpenIPMI' packages manually!"

fi
modprobe ipmi_devintf
modprobe ipmi_msghandler
# added this in case it can't modprobe ipmi_si, or load the driver /dev/ipmi0 workaround below:

modprobe ipmi_si
systemctl enable ipmievd.service
service ipmi start


function main_menu()
{
    while :
    do
        echo
        echo "####################################"
        echo "##  MAIN MENU IPMI CONFIGURATION  ##"
        echo "####################################"
        echo "##                                ##"
        echo "##     1. Reset IPMI password     ##"
        echo "##     2  Configure network       ##"
        echo "##     3. Reset IPMI COLD         ##"
        echo "##     4. Reset IPMI WARM         ##"
        echo "##                                ##"
	      echo "##     6. CONFIGURE NIC PORT      ##"
        echo "##                                ##"
        echo "##     0. Exit                    ##"
        echo "##                                ##"
        echo "####################################"
        echo "##          Beep boop Beep.       ##"
        echo "####################################"
        echo
        echo
        read -p "Please select your option: " m_choice
        echo
        echo

        case "$m_choice" in
            1)  clear
                echo "####################################################"
                echo "## Printing all users from the ipmitool user list ##"
                echo "####################################################"
                echo
                for i in `seq 1 14`; do ipmitool lan print $i 2>/dev/null | if grep -q ^Set; then ipmitool user list $i; fi done
                sub_menu_password
                ;;
            2)  sub_menu
                ;;
            3)  ipmitool mc reset cold
               echo -e "\033[0;31mIPMI is resetting, please wait until menu finished loading completely. This means that the reset has finished.\e[0m"
                ;;
            4)  ipmitool mc reset warm
               echo -e "\033[0;31mIPMI is resetting, please wait until menu finished loading completely. This means that the reset has finished.\e[0m"
                ;;
	    6) menu_nic
		;;
            0)  exit 0
                ;;
            *)  echo "Bad Option"
                echo
                ;;
        esac
    done
}

 function menu_nic()
 {
    while :
    do
	echo
	echo 
        echo "####################################"
        echo "##            WARNING             ##"
        echo "## ONLY WORKS ON DELL/SUPERMICRO  ##"
        echo "################################# ##"
        echo "##                                ##"
        echo "## 1. SET IPMI PORT TO DEDICATED  ##"
        echo "## 2. SET IPMI PORT TO SHARED     ##"
        echo "## 3. SET IPMI PORT TO FAILOVER   ##"
        echo "##                                ##"
        echo "## 0. Return to main menu         ##"
        echo "##                                ##"
        echo "####################################"

	echo "Currently it is set to: "
	ipmitool raw 0x30 0x70 0x0c 0
	echo "0x00 = Dedicated, 0x01 = Onboard / Shared, 0x02 = Failover"
	echo ""
	read -p "Please select your choice. Please note it may not always work on all systems and does not work on HP ProLiant servers" lan_choice

case "$lan_choice" in
	1) ipmitool raw 0x30 0x24 2
	;;
	2) ipmitool raw 0x30 0x24 0
	;;
	3) ipmitool raw 0x30 0x24 1
	;;
esac

 function sub_menu_password()
 {
    while :
    do
        echo
        echo
        read -p "Which ID should I reset? " s_choice_pass
        re='^[0-9]+$'
                if ! [[ $s_choice_pass =~ $re ]] ; then
                        echo "Not a valid number... Please enter a valid number" >&2;
                else
                        clear
                        ipmitool user set password $s_choice_pass Administrator && echo -e "Password reset to \033[0;31mAdministrator\e[0m of user ID '$s_choice_pass'. Enabling this user and returning to main menu" && ipmitool user enable $s_choice_pass;
		main_menu
                fi
done
}

 function sub_menu()
 {
    clear
    while :
    do
        echo
        echo "####################################"
        echo "##       CONFIGURE NETWORK        ##"
        echo "####################################"
        echo "##                                ##"
        echo "##   1. Configure IP adddress     ##"
        echo "##   2. Configure netmask         ##"
        echo "##   3. Configure gateway         ##"
ipmitool lan print 2 | if grep -q "DHCP"; then echo -e "##   4. Set to \e[92mSTATIC\e[0m             ##"; else echo -e "##   4. Set to \e[92mDHCP\e[0m               ##"; fi
        echo "##   5. IPMI reset COLD           ##"
        echo "##   6. IPMI reset WARM           ##"
        echo "##                                ##"
        echo "##                                ##"
        echo "##   0. Return to main menu       ##"
        echo "##                                ##"
        echo "####################################"

        read -p "Please select your option: " s_choice
        echo

        case "$s_choice" in
            1)  echo
                echo "Current IP address is:"
                for i in `seq 1 14`; do ipmitool lan print $i 2>/dev/null | grep "IP Address"; done
                echo
		echo
                echo "Please fill in the IP address you want to set: "
                read ADDRESS
                for i in `seq 1 14`; do ipmitool lan print $i 2>/dev/null | if grep -q ^Set; then ipmitool lan set $i ipaddr $ADDRESS; fi done
                echo -e "\033[0;31mIPMI reset required for changes to take effect\e[0m"
                ;;
            2)  echo
                echo "Current NETMASK is:"
                for i in `seq 1 14`; do ipmitool lan print $i 2>/dev/null | grep "Subnet Mask"; done
                echo
                echo
                echo "Please fill in the NETMASK you want to set: "
                read NETMASK
                for i in `seq 1 14`; do ipmitool lan print $i 2>/dev/null | if grep -q ^Set; then ipmitool lan set $i netmask $NETMASK; fi done
                echo -e "\033[0;31mIPMI reset required for changes to take effect\e[0m"
                ;;
            3)  echo
                echo "Current GATEWAY is:"
                for i in `seq 1 14`; do ipmitool lan print $i 2>/dev/null | grep "Default Gateway"; done
                echo
                echo
                echo "Please fill in the GATEWAY you want to set: "
                read GATEWAY
                for i in `seq 1 14`; do ipmitool lan print $i 2>/dev/null | if grep -q ^Set; then ipmitool lan set $i defgw ipaddr $GATEWAY; fi done
                echo -e "\033[0;31mIPMI reset required for changes to take effect\e[0m"
                ;;
            4) for i in `seq 1 14`; do ipmitool lan print $i 2>/dev/null | if grep -q "Static Address"; then ipmitool lan set $i ipsrc dhcp 2>/dev/null; fi done
                ;;
            5) ipmitool mc reset cold
               echo -e "\033[0;31mIPMI is resetting, please wait until menu finished loading completely. This means that the reset has finished.\e[0m"
                ;;
            6) ipmitool mc reset warm
               echo -e "\033[0;31mIPMI is resetting, please wait until menu finished loading completely. This means that the reset has finished.\e[0m"
                ;;
            0)  clear
                main_menu
                ;;
            *)  echo "Bad Option"
                echo
                ;;
        esac
    done
}

main_menu

exit 0
