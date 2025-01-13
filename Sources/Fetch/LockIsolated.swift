//
//  LockIsolated.swift
//  Fetch
//
//  Created by Guilherme Souza on 13/01/25.
//

import Foundation

package final class LockIsolated<Value>: @unchecked Sendable {

  let lock = NSRecursiveLock()
  var _value: Value

  package init(_ value: Value) {
    self._value = value
  }

  package func withValue<R>(_ f: (inout Value) throws -> R) rethrows -> R {
    try lock.withLock {
      var value = self._value
      defer { self._value = value }
      return try f(&value)
    }
  }
}

extension LockIsolated where Value: Sendable {
  package var value: Value {
    lock.withLock { self._value }
  }
}
