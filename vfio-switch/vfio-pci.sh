#!/bin/bash

usage() {
  echo "Usage: $0 [-v|--verbose] [-V|--vfio] [-p|--previous DEVICE] [-i|--device DEVICE] [-t|--toggle] [-h|--help]"
  echo "Options:"
  echo "  -v, --verbose         Enable verbose output"
  echo "  -V, --vfio            Load the vfio-pci driver"
  echo "  -p, --previous DEVICE Load the previous drivers"
  echo "  -d, --device          The devices of which the iommu group should switch drivers (standart is set to \"0000:0b:00.0\")"
  echo "  -h, --help            Show this help message and exit"
}

# Set a default value for the verbose option
VERBOSE=false
VFIO_DRIVER=false
PREVIOUS_DRIVER=false
CHECK_FOR_VM=false
DEVS="0000:0b:00.0"

OPTIONS=$(getopt -o vVpd:m:h --long verbose,vfio,previous,devices:,virtual_machine:,help -- "$@")
eval set -- "$OPTIONS"
while true; do
  case $1 in
    -v | --verbose )
      VERBOSE=true
      shift
      ;;
    -V | --vfio )
      VFIO_DRIVER=true
      shift
      ;;
    -p | --previous )
      PREVIOUS_DRIVER=true
      shift
      ;;
    -d | --devices )
      DEVS="$2"
      shift 2
      ;;
    -m | --virtual_machine )
      CHECK_FOR_VM=true
      if [[ -n "$2" && "${2:0:1}" != "-" ]]; then
        VM_TO_CHECK="$2"
        shift 2
      else
        VM_TO_CHECK=Windoof
        shift 1
      fi
      ;;
    -h | --help )
      usage
      exit 0
      ;;
    -- )
      shift
      break
      ;;
    * )
      echo "Invalid option: $1" 1>&2
      exit 1
      ;;
  esac
done


if (( "$(id -u)" != 0 )); then
  echo "This script must be run as root."
  exit 1
fi

verbose_echo() {
  if $VERBOSE ; then
    echo "$1"
  fi
}


load_kernel_module() {
  MODULE_NAME="$1"
  verbose_echo "attempting to load module for $MODULE_NAME"
  if lsmod | grep -q "^$MODULE_NAME "; then
    verbose_echo "$MODULE_NAME is already loaded"
  else
    modprobe -i "$MODULE_NAME"
    verbose_echo "$MODULE_NAME module was loaded"
  fi
}


PREVIOUS_DRIVER_FILES=$(find previous_drivers -maxdepth 1 -type f -name '*_previous_driver.txt' 2>/dev/null)

if $PREVIOUS_DRIVER &&  ! $VFIO_DRIVER || [[ -n "$PREVIOUS_DRIVER_FILES" ]]; then
    if $CHECK_FOR_VM && virsh list --name | grep -q "$VM_TO_CHECK"; then
        echo "$VM_TO_CHECK is still running"
    else
      for IOMMUDEV_FILE in previous_drivers/*_previous_driver.txt; do
          verbose_echo "----------"
          IOMMUDEV=${IOMMUDEV_FILE#previous_drivers/}
          IOMMUDEV=${IOMMUDEV%_previous_driver.txt}
          PREVIOUS_DRIVER=$(cat "$IOMMUDEV_FILE")
          load_kernel_module "$PREVIOUS_DRIVER"
          verbose_echo "Reloading $PREVIOUS_DRIVER driver for $IOMMUDEV"
          echo "$IOMMUDEV" > /sys/bus/pci/drivers/vfio-pci/unbind
          verbose_echo "load kernel module for driver $PREVIOUS_DRIVER"
          load_kernel_module "$PREVIOUS_DRIVER"
          verbose_echo "next is $IOMMUDEV bind"
          echo "$IOMMUDEV" > /sys/bus/pci/drivers/"$PREVIOUS_DRIVER"/bind
          verbose_echo "delete previous driver file for $IOMMUDEV"
          rm "$IOMMUDEV_FILE"
      done
    fi
else
    if [ -n "$(ls -A /sys/class/iommu)" ]; then
        load_kernel_module vfio_pci
        DEVICES_IN_USE=()
        for DEV in $DEVS; do
            if [[ -n "$(lsof -e /run/user/1000/doc -e /run/user/1000/gvfs -- /sys/bus/pci/devices/"$DEV")" ]]; then
                DEVICES_IN_USE+=("$DEV")
            fi
        done
        if (( ${#DEVICES_IN_USE[@]} > 0 )); then
            echo "The following devices are still in use by other processes: ${DEVICES_IN_USE[*]}"
            echo "check 'lsof -e /run/user/1000/doc -e /run/user/1000/gvfs -- /sys/bus/pci/devices/<DEV>' to see which processes block the device"
            echo "those need to be cleared before applying the vfio driver to them."
        else
          for DEV in $DEVS; do
              for IOMMUDEV_PATH in /sys/bus/pci/devices/"$DEV"/iommu_group/devices/*; do
                  IOMMUDEV=$(basename "$IOMMUDEV_PATH")
                  CURRENT_DRIVER=$(basename "$(readlink -f "$IOMMUDEV_PATH"/driver)")
                  if [[ "$CURRENT_DRIVER" != "vfio-pci" && "$CURRENT_DRIVER" != "pcieport" ]]; then
                      verbose_echo "----------"
                      verbose_echo "next is $IOMMUDEV unbind"
                      echo "$IOMMUDEV" > /sys/bus/pci/drivers/"$CURRENT_DRIVER"/unbind
                      verbose_echo "Save the driver of $IOMMUDEV => $CURRENT_DRIVER"
                      mkdir previous_drivers 2>/dev/null
                      echo "$CURRENT_DRIVER" > "previous_drivers/${IOMMUDEV}_previous_driver.txt"
                      verbose_echo "next is $IOMMUDEV bind"
                      echo "$IOMMUDEV" > /sys/bus/pci/drivers/vfio-pci/bind
                  elif [[ "$CURRENT_DRIVER" = "vfio-pci" ]]; then
                      verbose_echo "----------"
                      verbose_echo "$IOMMUDEV is already bound to vfio-pci"
                  fi
              done
          done
        fi
    fi
fi
