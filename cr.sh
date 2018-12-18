#!/bin/sh

wl_addr=`ifconfig wlan0|grep "inet addr"|cut  -d' ' -f11-12|cut -d':' -f2`
wl_prefix=`echo $wl_addr|cut -d'.' -f1-2`

echo wlprefix=$wl_prefix
if [ $wl_prefix != 10.133 ]; then 
#not FSOFT wireless, do nothing	
	exit 1
fi
	
#FSOFT wireless,change the route table
echo start to change the route table 

sudo route del default
sudo route add default gw 10.133.62.1 wlan0
#route add -net 192.168.1.0 netmask 255.255.255.0 dev eth0
#sudo route add -host 192.168.1.0 netmask 255.255.255.255 gw eth0
sudo route add -net 54.249.0.0 netmask 255.255.0.0 gw 10.133.12.10
sudo route add -net 54.178.0.0 netmask 255.255.0.0 gw 10.133.12.1
sudo route add -net 10.16.51.0 netmask 255.255.255.0 gw 10.133.12.4
sudo route add -net 54.92.0.0 netmask 255.255.0.0 gw 10.133.12.1
sudo route add -net 54.64.0.0 netmask 255.255.0.0 gw 10.133.12.1
sudo route add -net 54.65.0.0 netmask 255.255.0.0 gw 10.133.12.10
sudo route add -net 172.17.2.0 netmask 255.255.255.0 gw 10.133.12.10

