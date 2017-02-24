export PASSWD=$(sudo crudini --get /etc/ironic-inspector/inspector.conf swift password)
uuids=$(openstack baremetal node list --format value -c UUID)
mkdir hardware
pushd hardware > /dev/null
for uuid in $uuids; do
    swift -q -U service:ironic -K $PASSWD download ironic-inspector inspector_data-$uuid 2> /dev/null
done
popd > /dev/null

for f in $(ls ~/hardware/); do echo -n $f | sed s/inspector_data-//g; echo -n " "; cat ~/hardware/$f | jq '.inventory.disks' | grep -A 5 sda | grep wwn\" | tail -1 | awk {'print $2'} | sed -e s/,//g -e s/\"//g;  done > ~/uuid_to_wwn

while read UUID WWN ; do
      echo $UUID $WWN;
      ironic node-update $UUID remove properties/root_device
      ironic node-update $UUID add properties/root_device="{\"wwn\": \"$WWN\"}"
done < <(cat ~/uuid_to_wwn)
