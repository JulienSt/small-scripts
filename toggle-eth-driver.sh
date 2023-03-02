#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# Load the r8169 module
echo "attempting to load module for r8169"
if lsmod | grep -q "^r8169 "; then
    echo "r8169 is already loaded"
else
    modprobe r8169
    echo "r8169 module was loaded"
fi

# Load the vfio-pci module
echo "attempting to load module for vfio-pci"
if lsmod | grep -q "^vfio_pci "; then
    echo "vfio is already loaded"
else
    modprobe -i vfio-pci
    echo "vfio module was loaded"
fi


current_driver=$(ethtool -i eno1 | grep driver | awk '{print $2}')

if [ "$current_driver" == "r8169" ]; then
  echo "Switching to vfio-pci driver..."
  echo 0000:0c:00.0 > /sys/bus/pci/drivers/r8169/unbind
  echo 0000:0c:00.0 > /sys/bus/pci/drivers/vfio-pci/bind
  echo "reloading sfp card driver"
  echo 0000:07:00.0 > /sys/bus/pci/drivers/mlx4_core/unbind
  echo 0000:07:00.0 > /sys/bus/pci/drivers/mlx4_core/bind  
  echo "driver reloaded"
else
  echo "Switching to r8169 driver..."
  echo 0000:0c:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind
  echo 0000:0c:00.0 > /sys/bus/pci/drivers/r8169/bind
fi
