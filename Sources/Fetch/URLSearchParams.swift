//
//  URLSearchParams.swift
//  Fetch
//
//  Created by Guilherme Souza on 18/10/24.
//

import Foundation

public struct URLSearchParams: Sendable, CustomStringConvertible {
  var items: [(String, String?)]

  public init(_ url: URL) {
    self.init(url.absoluteString)
  }

  public init(_ url: String) {
    guard let query = url.split(separator: "?").last else {
      self.items = []
      return
    }

    let items = query.split(separator: "&").map { pair in
      let keyValue = pair.split(separator: "=", maxSplits: 1)
      return (String(keyValue.first!), keyValue.last?.removingPercentEncoding)
    }

    self.items = items
  }

  public mutating func append(_ name: String, _ value: Any) {
    items.append((name, String(describing: value)))
  }

  public mutating func delete(_ name: String, _ value: Any? = nil) {
    items.removeAll {
      $0.0 == name && ($0.1 == nil || $0.1 == String(describing: value!))
    }
  }

  public func get(_ name: String) -> String? {
    items.first { $0.0 == name }?.1
  }

  public func getAll(_ name: String) -> [String?] {
    items.filter { $0.0 == name }.map(\.1)
  }

  public func has(_ name: String) -> Bool {
    items.contains { $0.0 == name }
  }

  public func keys() -> [String] {
    items.map(\.0)
  }

  public mutating func sort() {
    items.sort { $0.0 < $1.0 }
  }

  public func values() -> [String?] {
    items.map(\.1)
  }

  public var description: String {
    items.map {
      "\($0.0)=\($0.1 ?? "")"
    }.joined(separator: "&")
  }
}
