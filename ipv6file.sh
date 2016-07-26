#!/bin/bash
sudo echo "nameserver 1.1.1.1" > /etc/resolv.conf
sudo echo "NETWORKING_IPV6=yes" >> /etc/sysconfig/network
sudo echo "IPV6FORWARDING=yes" >> /etc/sysconfig/network
sudo sed -i  's/IPV6INIT=no/IPV6INIT=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth0
sudo echo "DHCPV6C=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0
sudo systemctl restart network


