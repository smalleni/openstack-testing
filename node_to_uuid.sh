
declare -a node_type=(pcloud)
#declare -a node_type=(r620 r630 r730xd r930 6018r 6048r)
for baremetal_node in "${node_type[@]}"
    do 
        for i in $(openstack baremetal node list --format value -c UUID)
            do
                node=$(ironic node-show $i | grep $baremetal_node)
                if [ "$node" != "" ]
                    then
                     echo $i >> ~/$baremetal_node.txt
                fi
            done
    done
