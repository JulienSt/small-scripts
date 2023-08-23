#!/usr/bin/env amm

println("test")

val bla:Option[String] = Some("hey")

bla.foreach(println)
println(true)
printlt(null)

package example

import scala.collection.mutable

/** 
  * A simple HelloWorld app
  * @author YourName 
  */
object HelloWorld extends App derives Test[Bla] {
  val greeting: String = "Hello, World!"
  
  @inline def displayGreeting(message: String): Unit = {
    println(message)
  }

  displayGreeting(greeting)

  lazy val numbers = List(1, 2, 3, 4, 5)
  numbers.filter(_ > 2).foreach(println)
  println("bla" + 3*2)

  // Using a mutable Map
  val mutableMap: mutable.Map[String, Int] = mutable.Map("one" -> 1, "two" -> 2)
  mutableMap("three") = 3

  for ((k, v) <- mutableMap) {
    println(s"Key: $k, Value: $v")
  }
}

// This is a Comment with a ClassLikeWord which shouldn't be highlighted
/* This is another Comment
   with AnotherClassLikeWord
   and @Annotation which should be highlighted */

class ExampleClass(param1: String, param2: Int) {
  def methodExample: String = s"The value is ${param1} and ${param2}"

  // Inner comment with @InnerAnnotation
  val someValue: String = "StringValue"
}

object ExampleObject {
  def main(args: Array[String]): Unit = {
    println("Hello, world!")
  }
}

import ammonite.ops._

// Run the bluetoothctl show command to check Bluetooth status
val bluetoothShowOutput = %%("bluetoothctl", "show").out.string

// Check if Bluetooth is powered on
if (!bluetoothShowOutput.contains("Powered: yes ")) {
    // If not, power it on using bluetoothctl
    %("bluetoothctl", "power", "on")
}

// Fetch device MAC address using its name
val devicesOutput = %%("bluetoothctl", "devices").out.string
val maybeMouseLine = devicesOutput.lines.find(line => line.contains("MX Ergo"))
val mouseAddress = maybeMouseLine.map(_.split(" ")(1)).getOrElse("")

// If mouse MAC address found, check its connection status
if (mouseAddress.nonEmpty) {
    val deviceInfo = %%("bluetoothctl", "info", mouseAddress).out.string
    if (!deviceInfo.contains("Connected: yes")) {
        // If mouse is not connected, connect it
        %("bluetoothctl", "connect", mouseAddress)
    }
} else {
    println("Mouse MX Ergo not found.")
}
