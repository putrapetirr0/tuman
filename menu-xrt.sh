#!/bin/bash
P='\e[0;35m'
B='\033[0;36m'
N='\e[0m'
clear
echo -e "\e[36m╒════════════════════════════════════════════╕\033[0m"
echo -e " \E[0;47;30m          XRAY TROJAN TCP XTLS MENU         \E[0m"
echo -e "\e[36m╘════════════════════════════════════════════╛\033[0m

 [\033[1;36m•1 \033[0m]  Add XRAY TROJAN TCP XTLS Account
 [\033[1;36m•2 \033[0m]  Add Trial XRAY TROJAN TCP XTLS Account
 [\033[1;36m•3 \033[0m]  Check User Login XRAY TROJAN TCP XTLS
 [\033[1;36m•4 \033[0m]  Delete XRAY TROJAN TCP XTLS Account
 [\033[1;36m•5 \033[0m]  Renew XRAY TROJAN TCP XTLS Account
 [\033[1;36m•6 \033[0m]  Detail XRAY TROJAN TCP XTLS Config

 [\033[1;36m•0 \033[0m]  Back To Main Menu"
echo ""
echo -e " \033[1;37mPress [ Ctrl+C ] • To-Exit-Script\033[0m"
echo ""
read -p " Select menu : " opt
echo -e ""
case $opt in
1) clear ; add-xrt ;;
2) clear ; trial-xrt ;;
3) clear ; cek-xrt ;;
4) clear ; del-xrt ;;
5) clear ; renew-xrt ;;
6) clear ; user-xrt ;;
0) clear ; menu ;;
x) exit ;;
*) echo "Wrong Button" ; sleep 1 ; menu-xrt ;;
esac
