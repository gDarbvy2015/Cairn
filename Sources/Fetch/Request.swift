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
  public var method: Request.Method

  /// The body of the request. Supported types are (`Data`, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
  public var body: Request.Body?

  /// A dictionary of HTTP headers to be included in the request.
  public var headers: HTTPHeaders

  /// Initializes a new `RequestOptions` instance.
  /// - Parameters:
  ///   - method: The HTTP method for the request. Defaults to "GET".
  ///   - body: The body of the request. Supported types are (`Data`, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
  ///   - headers: A dictionary of HTTP headers. Defaults to an empty dictionary.
  public init(
    method: Request.Method = .get,
    body: Request.Body? = nil,
    headers: HTTPHeaders = [:]
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
  public var options: RequestOptions

  /// Initializes a new `Request` instance.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - options: Optional `RequestOptions` for the request.
  public init(url: URL, options: RequestOptions? = nil) {
    self.url = url
    self.options = options ?? RequestOptions()
  }

  public struct Method: RawRepresentable, Sendable, Hashable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(_ rawValue: String) {
      self.init(rawValue: rawValue)
    }

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
      self.init(rawValue: value)
    }

    public static let get = Method("GET")
    public static let post = Method("POST")
    public static let put = Method("PUT")
    public static let patch = Method("PATCH")
    public static let delete = Method("DELETE")
    public static let head = Method("HEAD")
    public static let options = Method("OPTIONS")
    public static let trace = Method("TRACE")
  }

  public enum Body: Sendable {
    case url(URL)
    case data(Data)
    case string(String, encoding: String.Encoding = .utf8)
    case formData(FormData)
    case urlSearchParams(URLSearchParams)
    case json(any Sendable)
    case encodable(any Encodable & Sendable, encoder: JSONEncoder? = nil)
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
