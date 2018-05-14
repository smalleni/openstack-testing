source ~/stackrc
uuids=$(openstack baremetal node list --format value -c UUID)
node_type=yamaha
disk=/dev/sda
mkdir ~/$node_type
pushd ~/$node_type > /dev/null
for uuid in $uuids; do
    node=$(openstack baremetal node show $uuid | grep driver_info | grep $node_type)
    if [ "$node" != "" ]
        then
            openstack baremetal introspection data save $uuid > ~/$node_type/$uuid
    fi
done
popd > /dev/null
for f in $(ls ~/$node_type/); do echo -n $f ; echo -n " "; cat ~/$node_type/$f | jq '.inventory.disks' | grep -B 4 $disk | grep -w wwn | awk {'print $2'} | sed -e s/,//g -e s/\"//g;  done > ~/uuid_to_wwn-${node_type}
while read UUID WWN ; do
      echo "Setting root disk on node $UUID with wwn $WWN"
      #openstack baremetal node unset $UUID --property root_device
      openstack baremetal node set $UUID --property root_device="{\"wwn\": \"$WWN\"}"
done < ~/uuid_to_wwn-${node_type}

