#!/bin/bash
restart_network(){
	echo "restart network"
	ccube-hardware mobile disable
	sleep 5
	ccube-hardware mobile enable
	ipdown wwan0
	sleep 5
	ipup wwan0
	sleep 5
}

restart_vpn(){
	echo "restart openvpn"
	systemctl restart openvpn
}

check_internet(){
	INT_IP=168.126.63.1
	ping -c 5 -W 2 ${INT_IP} 1>/dev/null
	INT_status=$?
}

check_vpn(){
	VPN_IP=10.8.0.1
	ping -c 5 -W 2 ${VPN_IP} 1>/dev/null 
	VPN_status=$?
}

check_internet
if [ ${INT_status} != 0 ] ; then
	restart_network		
fi

sleep 20

check_vpn
if [ ${VPN_status} != 0 ] ; then
	restart_vpn		
fi
