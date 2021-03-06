/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest

import TSCBasic
import SPMTestSupport
import PackageLoading

class ManifestLoadingPerfTests: XCTestCasePerf {
    let manifestLoader = ManifestLoader(manifestResources: Resources.default)

    func write(_ bytes: ByteString, body: (AbsolutePath) -> ()) {
        mktmpdir { path in
            let manifestFile = path.appending(component: "Package.swift")
            try localFileSystem.writeFileContents(manifestFile, bytes: bytes)
            body(path)
        }
    }

    func testTrivialManifestLoading_X1() {
        let N = 1
        let trivialManifest = ByteString(encodingAsUTF8: ("""
            import PackageDescription
            let package = Package(name: "Trivial")
            """))
        write(trivialManifest) { path in
            measure {
                for _ in 0..<N {
                    let manifest = try! self.manifestLoader.load(package: path, baseURL: "/Trivial", manifestVersion: .v4)
                    XCTAssertEqual(manifest.name, "Trivial")
                }
            }
        }
    }

    func testNonTrivialManifestLoading_X1() {
        let N = 1
        let manifest = ByteString(encodingAsUTF8: """
            import PackageDescription
            let package = Package(
                name: "Foo",
                dependencies: [
                    .package(url: "https://example.com/example", from: "1.0.0")
                ],
                targets: [
                    .target(name: "sys", dependencies: ["libc"]),
                    .target(name: "dep", dependencies: ["sys", "libc"])
                ]
            )
            """)

        write(manifest) { path in
            measure {
                for _ in 0..<N {
                    let manifest = try! self.manifestLoader.load(package: path, baseURL: "/Trivial", manifestVersion: .v4)
                    XCTAssertEqual(manifest.name, "Foo")
                }
            }
        }
    }
}
