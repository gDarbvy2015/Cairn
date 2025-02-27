//
//  Coding.swift
//  HTTP
//
//  Created by Guilherme Souza on 27/02/25.
//

import Foundation
import IssueReporting

extension JSONEncoder {
  package static let `default`: JSONEncoder = {
    var encoder = JSONEncoder()
    encoder.outputFormatting = isTesting ? [.sortedKeys] : []
    return encoder
  }()
}
