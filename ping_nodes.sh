source ~/stackrc
rm -f reachable.txt intermittent.txt unreachable.txt > /dev/null 2>&1
for ip in `openstack server list -f value -c Networks | sed s/ctlplane=//`
    do
       server=$(openstack server list | grep $ip | awk {'print$2'})
       node=$(openstack baremetal node list | grep $server | awk {'print$2'})
       TRY=0
       while [ "$TRY" -lt 2 ]
       do
           count=$(ping -c 5 $ip | grep received | awk {'print $4'})
           if [ "$count" -eq 5 ]
               then
                   echo Ironic node $node is pingable always >> reachable.txt
                   break
           elif [ "$count" -lt 5 && "$count" -gt 0 ]
               then
                   echo Ironic node $node is pingable intermittently >> intermittent.txt
                   break
           else
               if [ "$TRY" -eq 1 ]
                   then
                       echo Ironic node $node is not pingable >> unreachable.txt
               fi
           fi
           TRY=$((TRY+1))
       done
    done
