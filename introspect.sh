for node in $(openstack baremetal node list --format value -c UUID)
do
     introspection=$(ironic node-show $node | grep mem | grep 1024)
     if [ "$introspection" != "" ]
         then
             echo node $node did not introspect
     fi
done
