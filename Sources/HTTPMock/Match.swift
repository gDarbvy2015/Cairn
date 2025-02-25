//
//  Match.swift
//  Fetch
//
//  Created by Guilherme Souza on 14/01/25.
//

extension HTTPClientMock {
  public struct Match<Value: Sendable>: Sendable {
    var matches: @Sendable (Value?) -> Bool
  }
}

extension HTTPClientMock.Match {
  /// Matches any value.
  public static var any: Self { .init { _ in true } }

  public static func eq(_ v: Value) -> Self where Value: Equatable {
    Self { $0 == v }
  }

  public static func neq(_ v: Value) -> Self where Value: Equatable {
    Self { $0 != v }
  }

  public static func anyOf<S: Sequence & Sendable>(_ s: S) -> Self
  where S.Element == Value, Value: Equatable {
    Self {
      $0.map(s.contains) ?? false
    }
  }

  public static func substring<S: StringProtocol & Sendable>(_ s: S) -> Self
  where Value: StringProtocol {
    Self { $0?.contains(s) ?? false }
  }
}
