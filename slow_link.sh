node_type=5039ms
while true; do
for i in $(openstack server list --status active -f value -c ID); do
    echo server is $i
    node_uuid=$(openstack baremetal node list -f value | grep $i | awk {'print$1'})
    echo node is $node_uuid
    node_name=$(openstack baremetal node show "$node_uuid"  --fields driver_info -f json | jq '.driver_info.ipmi_address' | grep $node_type)
    if [ "$?" -eq 0 ]; then
        ip=$(openstack server show $i -f value | grep ctlplane | awk -F= {'print$2'})
        echo checking $node_name at IP $ip
        ssh $ip -o StrictHostKeyChecking=no -l heat-admin "ping -c 1 10.11.160.238"
        if [ "$?" -ne 0 ]
           then
           ssh -t $ip -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l heat-admin "sudo bash -c 'cat << 'EOF' > /etc/sysconfig/network-scripts/ifcfg-enp2s0f0
DEVICE="enp2s0f0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
EOF'"
           ssh -t $ip -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l heat-admin "sudo ifup enp2s0f0"
        fi
    fi
done
done

