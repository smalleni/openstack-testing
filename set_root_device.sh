export PASSWD=$(sudo crudini --get /etc/ironic-inspector/inspector.conf swift password)
uuids=$(openstack baremetal node list --format value -c UUID)
node_type=pcloud
mkdir $node_type
pushd $node_type > /dev/null
for uuid in $uuids; do
    node=$(ironic node-show $uuid | grep $node_type)
    if [ "$node" != "" ]
        then
            swift -q -U service:ironic -K $PASSWD download ironic-inspector inspector_data-$uuid 2> /dev/null
    fi
done
popd > /dev/null
for f in $(ls ~/$node_type/); do echo -n $f | sed s/inspector_data-//g; echo -n " "; cat ~/$node_type/$f | jq '.inventory.disks' | grep -A 5 sda | grep wwn\" | tail -1 | awk {'print $2'} | sed -e s/,//g -e s/\"//g;  done > ~/uuid_to_wwn
while read UUID WWN ; do
      echo "Setting root disk on node $UUID with wwn $WWN"
      ironic node-update $UUID remove properties/root_device
      ironic node-update $UUID add properties/root_device="{\"wwn\": \"$WWN\"}"
done < <(cat ~/uuid_to_wwn)
