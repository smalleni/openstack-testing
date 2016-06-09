ROUTER_ID="75f17462-216d-4113-a8da-199ab6e20cad"
IMAGE_NAME="centos7"
GUEST_SIZE="m1.small"
KEYSTONERC_ADMIN="/home/stack/overcloudrc"
KEY_NAME="sai-key"
SEARCH_STRING="overcloud-controller-0"
COUNT=0
if [ -f $KEYSTONERC_ADMIN ]; then
 source $KEYSTONERC_ADMIN
else
 echo "ERROR:: Unable to source Overcloud credentials"
 exit 1
fi
RUN=0
if [ -z $1 ] ; then
 RUN=1
else
 echo Run : $1
 RUN=$1
fi
while true
do
  echo "Networks launched is ${COUNT}"
  RUN=$((RUN+1))
  NETWORK="sai-${RUN}"
  SUBNET="12.0.${RUN}.0/24"
  if [ -z "$(neutron net-list | grep "${NETWORK}")" ]; then
   echo "Creating Subnets "
   neutron net-create $NETWORK
   neutron subnet-create $NETWORK $SUBNET
   neutron net-show $NETWORK
  fi
  IMAGE_ID=$(glance image-list | grep -E "${IMAGE_NAME}" | awk '{print $2}')
  NETWORKID=`nova network-list | grep -e "${NETWORK}\s" | awk '{print $2}'`
  neutron router-interface-add $ROUTER_ID `neutron net-list | grep ${NETWORKID} | awk '{print $6}'`
  INSTANCE_ID=$(nova boot --image ${IMAGE_ID} --nic net-id=${NETWORKID} --flavor ${GUEST_SIZE} --key-name $KEY_NAME instance-${RUN}  | egrep "\sid\s" | awk '{print $4}')
  while true
    do
      if ! [ -z "$(nova list | egrep -E "${INSTANCE_ID}" | egrep -E "ERROR")" ]; then
        echo "ERROR:: Guest in error state"
        exit 1
      fi
      if  [ "$(nova list | egrep -E "${INSTANCE_ID}" | egrep -E "Running" | wc -l)" -eq 1 ]; then
          echo "Instance ${INSTANCE_ID} is running"
        break
      fi
    done
  echo "Accessing console log"
  TRY=0
  METADATA=""
  while true
  do
    METADATA=`nova console-log $INSTANCE_ID | grep "${SEARCH_STRING}"`
    if ! [ -z "$METADATA" ] ; then
      echo "Metadata for instance ${INSTANCE_ID} on network ${NETWORK} injected"
      COUNT=$((COUNT+1))
      break
    else
      echo "Sleeping waiting for metadata to be injected"
      sleep 10
      if [ $TRY -eq 15 ]; then
        echo "Metadata no longer working"
        echo "Total networks attached to router is ${COUNT}"
        break 2
      fi
      TRY=$((TRY+1))
    fi
  done
done
