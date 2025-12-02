
GREEN="\e[32m"
CYAN="\e[36m"
RED="\e[31m"
NC="\e[0m"

echo -e "${CYAN}"
echo "==============================================="
echo "     ARUBA CLOUD AUTO IP MANAGER"
echo "     Created by: TRB Sami  |  @trbsami"
echo "==============================================="
echo -e "${NC}"


echo -e "${GREEN}[+] Detecting network interfaces...${NC}"

MAC_IF1="fa:16:3e:c1:63:68"
MAC_IF2="fa:16:3e:e9:a1:d2"

IF1=$(ip -o link | grep "$MAC_IF1" | awk -F': ' '{print $2}')
IF2=$(ip -o link | grep "$MAC_IF2" | awk -F': ' '{print $2}')

if [[ -z "$IF1" || -z "$IF2" ]]; then
    echo -e "${RED}[-] Error: Could not detect interfaces.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Ethernet 01 → $IF1${NC}"
echo -e "${GREEN}[+] Ethernet 02 → $IF2${NC}"
echo


echo -e "${CYAN}[?] Enter your SECOND PUBLIC IP to set:${NC}"
read -p "> " NEW_IP

if [[ -z "$NEW_IP" ]]; then
    echo -e "${RED}[-] ERROR: IP cannot be empty.${NC}"
    exit 1
fi

GW=$(echo "$NEW_IP" | awk -F. '{print $1"."$2"."$3".1"}')

MASK=24
DNS1="8.8.8.8"
DNS2="1.1.1.1"

echo
echo -e "${GREEN}[+] New IP: $NEW_IP/$MASK${NC}"
echo -e "${GREEN}[+] Gateway: $GW${NC}"
echo


echo -e "${CYAN}[?] Do you want to REMOVE the FIRST IP from $IF1? (y/n)${NC}"
read -p "> " DEL_ANSWER

DELETE_IP1=false
if [[ "$DEL_ANSWER" == "y" || "$DEL_ANSWER" == "Y" ]]; then
    DELETE_IP1=true
    echo -e "${GREEN}[+] First IP will be removed.${NC}"
else
    echo -e "${GREEN}[+] First IP will remain active.${NC}"
fi


NETPLAN="/etc/netplan/01-aruba-netcfg.yaml"

echo -e "${GREEN}[+] Creating new netplan config...${NC}"

cp $NETPLAN ${NETPLAN}.bak.$(date +%s) 2>/dev/null

echo "network:
  version: 2
  ethernets:" > $NETPLAN

if $DELETE_IP1; then
    echo "    $IF1:
      dhcp4: no" >> $NETPLAN
else
    FIRST_IP=$(ip -4 a show $IF1 | grep inet | awk '{print $2}')
    echo "    $IF1:
      dhcp4: no
      addresses:
        - $FIRST_IP" >> $NETPLAN
fi

echo "
    $IF2:
      dhcp4: no
      addresses:
        - $NEW_IP/$MASK
      gateway4: $GW
      nameservers:
        addresses:
          - $DNS1
          - $DNS2
" >> $NETPLAN

chmod 600 $NETPLAN



echo -e "${GREEN}[+] Applying netplan...${NC}"
netplan apply

ip link set $IF2 up

echo
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}[✔] Done! New IP has been successfully applied.${NC}"
echo -e "${GREEN}===============================================${NC}"
echo
ip a
