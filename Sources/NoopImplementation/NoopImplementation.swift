@attached(peer, names: prefixed(Noop))
public macro NoopImplementation(
    overrides: [String: Any] = [:]
) = #externalMacro(module: "NoopImplementationMacros", type: "NoopImplementationMacro")
