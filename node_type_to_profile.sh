source ~/stackrc
declare -A node_to_profile
node_to_profile[r620]=r620-compute
node_to_profile[r630]=r630-compute
node_to_profile[r730xd]=r730xd-compute
node_to_profile[r930]=r930-compute
node_to_profile[6018r]=6018r-compute
node_to_profile[6048r]=6048r-compute
for node_type in "${!node_to_profile[@]}"
    do 
        echo "Setting profile for node type $node_type"
        for i in $(openstack baremetal node list --format value -c UUID)
            do  
                node=$(openstack baremetal node show $i | grep driver_info | grep $node_type)
                if [ "$node" != "" ]
                    then
                        echo "Updating node $i with profile ${node_to_profile[$node_type]}"
                        openstack baremetal node set $i --property capabilities=profile:${node_to_profile[$node_type]},boot_option:local
                fi
            done
    done
