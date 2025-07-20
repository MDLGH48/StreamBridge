
import Foundation
// Import ObjectBox for the types that generated code will use
import ObjectBox

@attached(peer)
public macro StatefulObject() =
    #externalMacro(module: "StreamBridgeMacros", type: "StatefulObjectGenMacro")


public class StateStore {}
