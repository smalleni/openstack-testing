#!/bin/bash
function cleanup() {
    source ~/stackrc
    openstack stack delete overcloud --yes --wait
}

function deploy() {
    source ~/stackrc
    openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e templates/network-environment.yaml -e templates/deploy.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/services-docker/neutron-opendaylight.yaml -e templates/opendaylight-transactions.yaml -e /home/stack/docker_registry.yaml -e templates/neutron-policy.yaml --ntp-server clock.redhat.com >> deploy_log.txt
    if [ $? == 0 ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT+1))
        echo "Success count is ${SUCCESS_COUNT}"
    else
        FAILURE_COUNT=$((FAILURE_COUNT+1))
        echo "Failure count is ${FAILURE_COUNT}"
    fi
}

function ironic_cleaning() {
        source ~/stackrc
        while true; do
            failed_nodes=$(openstack baremetal node list | grep failed | awk {'print$2'})
            if [ "$failed_nodes" != "" ]; then
                for node in $failed_nodes; do
                    openstack baremetal node maintenance unset $node
                    openstack baremetal node manage $node
                    openstack baremetal node provide $node
                done
                sleep 300
            elif [ "$failed_nodes" == "" ]; then
                break
            fi
         done
         while true; do
             wait_nodes=$(openstack baremetal node list | grep "clean wait" | awk {'print$2'})
             if [ "$wait_nodes" != "" ]; then
                 for node in $wait_nodes; do
                     openstack baremetal node maintenance set $node
                     openstack baremetal node abort $node
                     openstack baremetal node maintenance unset $node
                     openstack baremetal node manage $node
                     openstack baremetal node provide $node
                 done
                 sleep 300
             elif [ "$wait_nodes" == "" ]; then
                 break

             fi
         done
}
SUCCESS_COUNT=0
FAILURE_COUNT=0
TIMES=$1
ITER=0
while [ $ITER -lt $TIMES ]; do
    deploy
    cleanup
    #wait for ironic cleaning
    sleep 300
    ironic_cleaning
    ITER=$((ITER+1))
done

echo "Test completed"
echo "The total number of successes is $SUCCESS_COUNT"
echo "The total number of failure is $FAILURE_COUNT"

