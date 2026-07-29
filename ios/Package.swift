// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "share_harbor",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ShareHarborCore",
            targets: ["ShareHarborCore"]
        )
    ],
    targets: [
        .target(
            name: "ShareHarborCore",
            path: "Classes/Core",
            resources: [
                .process("../../PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
