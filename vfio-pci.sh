#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# Set a default value for the verbose option
VERBOSE=false

# Parse command-line options
while getopts ":v" opt; do
  case ${opt} in
    v )
      VERBOSE=true
      ;;
    \? )
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

verbose_echo() {
  if [ "$VERBOSE" = true ]; then
    echo "$1"
  fi
}


load_kernel_module() {
  MODULE_NAME="$1"
  verbose_echo "attempting to load module for $MODULE_NAME"
  if lsmod | grep -q "^$MODULE_NAME "; then
    verbose_echo "$MODULE_NAME is already loaded"
  else
    modprobe -i $MODULE_NAME
    verbose_echo "$MODULE_NAME module was loaded"
  fi
}

load_kernel_module vfio_pci

if [ -n "$(find previous_drivers -maxdepth 1 -type f -name '*_previous_driver.txt')" ]; then
    for IOMMUDEV_FILE in previous_drivers/*_previous_driver.txt; do
        IOMMUDEV=${IOMMUDEV_FILE#previous_drivers/}
        IOMMUDEV=${IOMMUDEV%_previous_driver.txt}
        PREVIOUS_DRIVER=$(cat "$IOMMUDEV_FILE")
        modprobe $PREVIOUS_DRIVER
        verbose_echo "Reloading $PREVIOUS_DRIVER driver for $IOMMUDEV"
        echo "$IOMMUDEV" > /sys/bus/pci/drivers/vfio-pci/unbind
        verbose_echo "load kernel module for driver $PREVIOUS_DRIVER"
        load_kernel_module $PREVIOUS_DRIVER
        verbose_echo "next is $IOMMUDEV bind"
        echo "$IOMMUDEV" > /sys/bus/pci/drivers/$PREVIOUS_DRIVER/bind
        verbose_echo "delete previous driver file for $IOMMUDEV"
        rm "$IOMMUDEV_FILE"
    done
else
    # Bind devices to vfio-pci
    DEVS="0000:0b:00.0"
    if [ ! -z "$(ls -A /sys/class/iommu)" ]; then
        for DEV in $DEVS; do
            for IOMMUDEV in $(ls /sys/bus/pci/devices/$DEV/iommu_group/devices/* 2>/dev/null | grep -v 'pci_bus'); do
                CURRENT_DRIVER=$(basename $(readlink /sys/bus/pci/devices/$IOMMUDEV/driver))
                if [ "$CURRENT_DRIVER" != "vfio-pci" ]; then
                    verbose_echo "next is $IOMMUDEV unbind"
                    echo "$IOMMUDEV" > /sys/bus/pci/drivers/$CURRENT_DRIVER/unbind
                    verbose_echo "Save the driver of $IOMMUDEV => $CURRENT_DRIVER"
                    echo "$CURRENT_DRIVER" > "previous_drivers/${IOMMUDEV}_previous_driver.txt"
                    verbose_echo "next is $IOMMUDEV bind"
                    echo "$IOMMUDEV" > /sys/bus/pci/drivers/vfio-pci/bind
                else
                    verbose_echo "$IOMMUDEV is already bound to vfio-pci"
                fi
            done
        done
    fi
fi
