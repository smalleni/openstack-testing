#!/bin/bash

#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

# Heavily borrowed from Numan Siddique's script to build overcloud image for OVN

TMP_OC_IMAGE_MOUNT_PATH=/tmp/oc_mnt
ODL_IMAGE_PATH=/home/stack
OVERCLOUD_IMAGE_FILE=overcloud-full.qcow2
mount_oc_image() {
    which guestmount
    if [ "$?" != "0" ]; then
        echo "Please install libguestfs-tools and retry"
        exit 1
    fi
    export LIBGUESTFS_BACKEND=direct
    mkdir -p $TMP_OC_IMAGE_MOUNT_PATH
    guestmount -a $ODL_IMAGE_PATH/$OVERCLOUD_IMAGE_FILE -m /dev/sda $TMP_OC_IMAGE_MOUNT_PATH
    return $?
}

run_command_in_oc_image() {
    export LIBGUESTFS_BACKEND=direct
    args=$@
    virt-customize -a $ODL_IMAGE_PATH/overcloud-full.qcow2 --run-command "$args"
}
install_odl_repo() {
      mount_oc_image
      sudo sh -c 'cat << EOF > $TMP_OC_IMAGE_MOUNT_PATH/etc/yum.repos.d/odl.repo
[opendaylight-5-testing]
name=CentOS CBS OpenDaylight Boron testing repository
baseurl=http://cbs.centos.org/repos/nfv7-opendaylight-5-testing/$basearch/os/
enabled=1
gpgcheck=0
EOF'
      guestunmount $TMP_OC_IMAGE_MOUNT_PATH
}
install_odl_repo
run_command_in_oc_image "sudo yum install opendaylight -y"

