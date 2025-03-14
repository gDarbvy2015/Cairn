//
//  Coding.swift
//  HTTP
//
//  Created by Guilherme Souza on 27/02/25.
//

import Foundation

extension JSONEncoder {
  package static let `default`: JSONEncoder = {
    var encoder = JSONEncoder()
    encoder.outputFormatting = ProcessInfo.processInfo.isTesting ? [.sortedKeys] : []
    return encoder
  }()
}

extension ProcessInfo {
  fileprivate var isTesting: Bool {
    if environment.keys.contains("XCTestBundlePath") { return true }
    if environment.keys.contains("XCTestConfigurationFilePath") { return true }
    if environment.keys.contains("XCTestSessionIdentifier") { return true }

    return arguments.contains { argument in
      let path = URL(fileURLWithPath: argument)
      return path.lastPathComponent == "swiftpm-testing-helper"
        || argument == "--testing-library"
        || path.lastPathComponent == "xctest"
        || path.pathExtension == "xctest"
    }
  }
}
