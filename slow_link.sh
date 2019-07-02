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
        count=$(ssh $ip -o StrictHostKeyChecking=no -l heat-admin "ping -c 1 clock1.rdu2.redhat.com | grep received | awk {'print \$4'}")
        echo Ping count is $count
        if [ "$count" -ne 1 ]
           then
           ssh -t $i -o StrictHostKeyChecking=no -l heat-admin "sudo ifup enp2s0f0"
        fi
    fi
done
done
