// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "noop-implimention-macro",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NoopImplementation",
            targets: ["NoopImplementation"]
        ),
        .executable(
            name: "NoopImplementationClient",
            targets: ["NoopImplementationClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "NoopImplementationMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes the macro implementation to clients.
        .target(
            name: "NoopImplementation", 
            dependencies: [
                // Add dependency here
                .target(name: "NoopImplementationMacros")
            ]
        ),

        // A client of the library, which is able to use the macro expansion provided by the library.
        .executableTarget(
            name: "NoopImplementationClient", 
            dependencies: ["NoopImplementation"]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "NoopImplementationTests",
            dependencies: [
                "NoopImplementationMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
