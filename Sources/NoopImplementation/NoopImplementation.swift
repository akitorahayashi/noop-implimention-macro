@attached(peer, names: prefixed(Noop))
public macro NoopImplementation(
) = #externalMacro(module: "NoopImplementationMacros", type: "NoopImplementationMacro")
