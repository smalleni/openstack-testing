if [[ $# -eq 0 ]]; then
        echo "USAGE:"
        echo "./create_flavors.sh flavor1 flavor2"
        exit 1
fi

source ~/stackrc
for flavor in "$@"
do
     openstack flavor create --id auto --ram 4096 --disk 40 --vcpus 1 $flavor
     openstack flavor set --property "capabilities:boot_option"="local" --property "capabilities:profile"="${flavor}" $flavor
     openstack flavor set $flavor --property "resources:VCPU"="0"
     openstack flavor set $flavor --property "resources:MEMORY_MB"="0"
     openstack flavor set $flavor --property "resources:DISK_GB"="0"
     openstack flavor set $flavor --property "resources:CUSTOM_BAREMETAL"="1" 
done
    
    

