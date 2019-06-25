source ~/stackrc
declare -A node_to_profile
node_to_profile[5039ms]=5039ms-compute
node_to_profile[1029p]=1029p-compute
for node_type in "${!node_to_profile[@]}"
    do
        echo "Setting profile for node type $node_type"
        for i in $(openstack baremetal node list --format value -c UUID)
            do
                node=$(openstack baremetal node show $i --fields driver_info -f json | jq '.driver_info.ipmi_address' | grep $node_type)
                if [ "$node" != "" ]
                    then
                        echo "Updating node $i with profile ${node_to_profile[$node_type]} and ip $(openstack baremetal node show $i --fields driver_info -f json | jq '.driver_info.ipmi_address')"
                        openstack baremetal node set $i --property capabilities=profile:${node_to_profile[$node_type]},cpu_vt:true,cpu_hugepages:true,boot_option:local,cpu_txt:true,cpu_aes:true,cpu_hugepages_1g:true,boot_mode:bios

                fi
            done
    done

