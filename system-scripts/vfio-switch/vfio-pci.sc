#!/usr/bin/env amm

@main
def switchDriver(
  verbose: Boolean = false,
  vfio: Boolean = false,
  previous: Option[String] = None,
  devices: String = "0000:0b:00.0",
  virtual_machine: Option[String] = None,
  ignore: Option[String] = None
): Unit = {

  if (!isRoot) {
    println("This script must be run as root.")
    sys.exit(1)
  }

  def verboseEcho(message: String) = if (verbose) println(message)

  def loadKernelModule(moduleName: String): Unit = {
    verboseEcho(s"Attempting to load module for $moduleName")
    if (call("lsmod").lines.contains(s"^$moduleName ")) {
      verboseEcho(s"$moduleName is already loaded")
    } else {
      call("modprobe", "-i", moduleName)
      verboseEcho(s"$moduleName module was loaded")
    }
  }

  val previousDriverFilesPath = os.pwd / "previous_drivers"
  val previousDriverFiles = os.list(previousDriverFilesPath)
    .filter(_.last.endsWith("_previous_driver.txt"))

  if (previous.isDefined && !vfio || previousDriverFiles.nonEmpty) {
    if (virtual_machine.isDefined && call("virsh", "list", "--name").lines.contains(virtual_machine.get)) {
      println(s"${virtual_machine.get} is still running")
    } else {
      previousDriverFiles.foreach { file =>
        verboseEcho("----------")
        val iommuDev = file.last.stripSuffix("_previous_driver.txt")
        val prevDriver = os.read(file)
        loadKernelModule(prevDriver)
        verboseEcho(s"Reloading $prevDriver driver for $iommuDev")

        // Unbinding and other logic...
      }
    }
  } else {
    val iommuPath = os.pwd / "sys" / "class" / "iommu"
    if (os.isDir(iommuPath) && os.list(iommuPath).nonEmpty) {
      devices.split(" ").foreach { device =>
        val iommuDevPath = os.pwd / "sys" / "bus" / "pci" / "devices" / device / "iommu_group" / "devices"

        os.list(iommuDevPath).foreach { path =>
          val iommuDev = path.last
          val currentDriver = os.read(os.pwd / path / "driver").trim

          if (currentDriver != "vfio-pci" && currentDriver != "pcieport") {
            // And so on...
          }
        }
      }
    }
  }
}

