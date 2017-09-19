source ~/stackrc
declare -A node_to_pinning
node_to_pinning[r620]=r620-compute
node_to_pinning[r630]=r630-compute
node_to_pinning[r730xd]=r730xd-compute
node_to_pinning[r930]=r930-compute
node_to_pinning[6018r]=6018r-compute
node_to_pinning[6048r]=6048r-compute
for node_type in "${!node_to_pinning[@]}"
    do 
        COUNT=0
        echo "Setting pinning for node type $node_type"
        for i in $(openstack baremetal node list --format value -c UUID)
            do  
                node=$(openstack baremetal node show $i | grep -A 4 driver_info | grep $node_type)
                if [ "$node" != "" ]
                    then
                        echo "Updating node $i with pinning ${node_to_pinning[$node_type]}-$COUNT"
                        openstack baremetal node set $i --property capabilities=node:${node_to_pinning[$node_type]}-${COUNT},boot_option:local
                        COUNT=$((COUNT+1))
                fi
            done
    done
