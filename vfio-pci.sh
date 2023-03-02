#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# Load the vfio-pci module
echo "attempting to load module for vfio-pci"
if lsmod | grep -q "^vfio_pci "; then
    echo "vfio is already loaded"
else
    modprobe -i vfio-pci
    echo "vfio module was loaded"
fi

# Bind devices to vfio-pci
DEVS="0000:0b:00.0"
if [ ! -z "$(ls -A /sys/class/iommu)" ]; then
    for DEV in $DEVS; do
        for IOMMUDEV in $(ls /sys/bus/pci/devices/$DEV/iommu_group/devices) ; do
            CURRENT_DRIVER=$(basename $(readlink /sys/bus/pci/devices/$IOMMUDEV/driver))
            if [ "$CURRENT_DRIVER" != "vfio-pci" ]; then
                echo "next is $IOMMUDEV unbind"
                echo "$IOMMUDEV" > /sys/bus/pci/drivers/$CURRENT_DRIVER/unbind
                echo "next is $IOMMUDEV bind"
                echo "$IOMMUDEV" > /sys/bus/pci/drivers/vfio-pci/bind
            else
                echo "$IOMMUDEV is already bound to vfio-pci"
            fi
        done  
    done
fi
