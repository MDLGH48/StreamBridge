// Sources/StreamBridge/StreamBridge.swift
import Foundation

// Import ObjectBox for the types that generated code will use
import ObjectBox

// Declare the macro so users can use it
@attached(peer)
public macro StatefulObject() = #externalMacro(module: "StreamBridgeMacros", type: "StatefulObjectMacro")

