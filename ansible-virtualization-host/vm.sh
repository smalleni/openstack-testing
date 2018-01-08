virt-install --import --name=test9\
         --virt-type=kvm\
         --disk path=/var/lib/libvirt/images/rhel-guest-image-7.4-191.x86_64.qcow2\
         --vcpus=2\
         --ram=2048\
         --network bridge=br1\
         --network bridge=br0\
         --os-type=lix\
         --os-variant=rhel7\
         --graphics vnc \
         --serial pty \
         --check path_in_use=off\
         --noautoconsole

