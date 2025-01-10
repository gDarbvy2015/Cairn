//
//  Request.swift
//  Fetch
//
//  Created by Guilherme Souza on 08/01/25.
//

import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Represents options for an HTTP request.
public struct RequestOptions: Sendable {
  /// The HTTP method for the request (e.g., "GET", "POST", "PUT", etc.).
  public var method: String

  /// The body of the request. Supported types are (`Data`,, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
  public var body: (any Sendable)?

  /// A dictionary of HTTP headers to be included in the request.
  public var headers: [String: String]

  /// Initializes a new `RequestOptions` instance.
  /// - Parameters:
  ///   - method: The HTTP method for the request. Defaults to "GET".
  ///   - body: The body of the request. Supported types are (`Data`, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
  ///   - headers: A dictionary of HTTP headers. Defaults to an empty dictionary.
  public init(
    method: String = "GET",
    body: (any Sendable)? = nil,
    headers: [String: String] = [:]
  ) {
    self.method = method
    self.body = body
    self.headers = headers
  }
}

/// Represents an HTTP request.
public struct Request: Sendable {
  /// The URL for the request.
  public var url: URL

  /// Optional `RequestOptions` for the request.
  public var options: RequestOptions?

  /// Initializes a new `Request` instance.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - options: Optional `RequestOptions` for the request.
  public init(url: URL, options: RequestOptions? = nil) {
    self.url = url
    self.options = options
  }
}

extension Request {
  /// Initializes a new `Request` instance with a string URL.
  /// - Parameters:
  ///   - url: A string representation of the URL.
  ///   - options: Optional `RequestOptions` for the request.
  /// - Warning: This initializer force-unwraps the URL. Ensure the URL string is valid.
  public init(url: String, options: RequestOptions? = nil) {
    self.init(url: URL(string: url)!, options: options)
  }
}
