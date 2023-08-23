def call(command: String*) = {
    String(os.proc(command).call().out.bytes)
}

def currentUID = call("id", "-u").trim.toInt

def isRoot = currentUID == 0
