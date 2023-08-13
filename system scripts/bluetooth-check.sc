#!/usr/bin/env amm

import scala.util.{Try, Failure, Success}

def call(command: String*) = {
    String(os.proc(command).call().out.bytes)
}

val uid = call("id", "-u").trim.toInt

if (uid == 0) {

    if (!call("bluetoothctl", "show").contains("Powered: yes")) {
        Try(call("bluetoothctl", "power", "on")) match {
            case Failure(_) =>
                call("rfkill", "block", "bluetooth")
                call("rfkill", "unblock", "bluetooth")
                Try(call("bluetoothctl", "power", "on"))
            case Success(_) =>
        }
    }

    val maybeMouseLine =
        call("bluetoothctl", "devices")
            .split('\n')
            .find(line => line.contains("MX Ergo"))
    val maybeMouseAddress = maybeMouseLine.map(_.split(" ")(1))

    maybeMouseAddress match {
        case Some(address) =>
            val deviceInfo = call("bluetoothctl", "info", address)
            if (!deviceInfo.contains("Connected: yes")) {
                Try(call("bluetoothctl", "connect", address))
            }
        case None =>
    }

} else {
    println(s"Script must be executed as root. Current userID: ${uid}")
}
