//
//  FetchMock.swift
//  Fetch
//
//  Created by Guilherme Souza on 13/01/25.
//

import Fetch

public actor FetchMock: Fetch {

  public init() {}

  public struct Match<Value: Sendable>: Sendable {
    var matches: @Sendable (Value?) -> Bool
  }

  struct Mock {
    var scheme: Match<String>
    var host: Match<String>
    var port: Match<Int>
    var path: Match<String>
    var query: Match<String>
    var returns: (Request) throws -> Response
  }

  private var mocks: [Mock] = []

  @discardableResult
  public func register(
    scheme: Match<String> = .any,
    host: Match<String> = .any,
    port: Match<Int> = .any,
    path: Match<String> = .any,
    query: Match<String> = .any,
    returns: @escaping (Request) throws -> Response
  ) -> Self {
    mocks.append(
      Mock(
        scheme: scheme,
        host: host,
        port: port,
        path: path,
        query: query,
        returns: returns
      )
    )
    return self
  }

  public func callAsFunction(_ request: Request) async throws -> Response {
    guard let mock = findMock(for: request) else {
      fatalError("Mock not found.")
    }

    return try mock.returns(request)
  }

  private func findMock(for request: Request) -> Mock? {
    mocks.first { mock in
      mock.scheme.matches(request.url.scheme)
        && mock.host.matches(request.url.host)
        && mock.port.matches(request.url.port)
        && mock.path.matches(request.url.path)
        && mock.query.matches(request.url.query)
    }
  }
}

extension FetchMock.Match {
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
