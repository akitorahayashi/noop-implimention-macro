// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: prefixed(Noop))
public macro NoopImplementation(
) = #externalMacro(module: "NoopImplementationMacros", type: "NoopImplementationMacro")
