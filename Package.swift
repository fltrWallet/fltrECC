// swift-tools-version:5.3

import PackageDescription

let enableAsmx86 = false
let enableModuleRecovery = true
let enableModuleEcdh = true
let enableModuleExtraKeys = true
let enableModuleSchnorrsig = true

var cSettings: [CSetting] = [
     .headerSearchPath("src")
    , .define("ECMULT_GEN_PREC_BITS", to: "4")
    , .define("ECMULT_WINDOW_SIZE", to: "15")
    , .define("HAVE_DLFCN_H", to: "1")
    , .define("HAVE_INTTYPES_H", to: "1")
    , .define("HAVE_STDINT_H", to: "1")
    , .define("HAVE_STDIO_H", to: "1")
    , .define("HAVE_STDLIB_H", to: "1")
    , .define("HAVE_STRINGS_H", to: "1")
    , .define("HAVE_STRING_H", to: "1")
    , .define("HAVE_SYS_STAT_H", to: "1")
    , .define("HAVE_SYS_TYPES_H", to: "1")
    , .define("HAVE_UNISTD_H", to: "1")
    , .define("STDC_HEADERS", to: "1")
]

if enableModuleRecovery {
    cSettings.append(.define("ENABLE_MODULE_RECOVERY", to: "1"))
}

if enableModuleEcdh {
    cSettings.append(.define("ENABLE_MODULE_ECDH", to: "1"))
}

if enableAsmx86 {
    #if arch(x86_64)
    cSettings.append(.define("USE_ASM_X86_64", to: "1"))
    #endif
}

if enableModuleExtraKeys {
    cSettings.append(.define("ENABLE_MODULE_EXTRAKEYS", to: "1"))
}

if enableModuleSchnorrsig {
    cSettings.append(.define("ENABLE_MODULE_SCHNORRSIG", to: "1"))
}

let package = Package(
    name: "fltrECC",
    products: [
        .library(name: "fltrECC",
                 targets: ["fltrECC"]),
        .library(name: "fltrECCTesting",
                 targets: ["fltrECCTesting"]),
        .library(
            name: "fltrECCAdapater",
            targets: ["fltrECCAdapter"]),
    ],
    targets: [
        .target(
            name: "Csecp256k1",
            dependencies: [],
            path: "Sources/secp256k1",
            sources: [ "src/secp256k1.c",
                       "src/precomputed_ecmult.c",
                       "src/precomputed_ecmult_gen.c", ],
            cSettings: cSettings
        ),
        .target(
            name: "fltrECCAdapter",
            dependencies: ["Csecp256k1"]
        ),
        .target(
            name: "fltrECC",
            dependencies: ["fltrECCAdapter"]),
        .target(
            name: "fltrECCTesting",
            dependencies: ["fltrECCAdapter"]
        ),
        .testTarget(
            name: "fltrECCTests",
            dependencies: ["fltrECC", "fltrECCTesting"]),
        .testTarget(
            name: "fltrECCAdapterTests",
            dependencies: ["fltrECCAdapter", "fltrECCTesting"]),
    ]
)
