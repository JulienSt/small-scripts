 VFIO Device Passthrough Script

This shell script allows you to easily switch the drivers of a device or group of devices from their current driver to the vfio-pci driver, which is commonly used for device passthrough to a virtual machine. The script can also switch the devices back to their previous drivers if needed.
Prerequisites

This script requires the following dependencies to be installed:

    A shell environment (e.g. bash)
    The modprobe utility
    The lsmod utility
    Root privileges

Usage

To use the script, simply run it with root privileges and pass any necessary options. The following command-line options are available:

    -v or --verbose: Enables verbose output.
    -V or --vfio: Loads the vfio-pci driver.
    -p or --previous: Loads the previous drivers.
    -d or --device: Specifies the device or devices of which the IOMMU group should switch drivers. The default device is 0000:0b:00.0.
    -h or --help: Shows the help message and exits.

For example, to switch the device with PCI address 0000:0b:00.0 to vfio-pci, run the following command:

bash

sudo ./vfio-switch.sh -d 0000:0b:00.0

You can also switch multiple devices by specifying them as a comma-separated list:

bash

sudo ./vfio-switch.sh -d 0000:0b:00.0,0000:0c:00.0

To switch the devices back to their previous drivers, run the following command:

bash

sudo ./vfio-switch.sh -p
