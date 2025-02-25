//
//  Request.swift
//  Fetch
//
//  Created by Guilherme Souza on 08/01/25.
//

import Foundation
import HTTPTypes

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Represents an HTTP request.
//public struct Request: Sendable {
//  /// The URL for the request.
//  public var url: URL
//
//  /// The HTTP method for the request (e.g., "GET", "POST", "PUT", etc.).
//  public var method: HTTPMethod
//
//  /// The body of the request. Supported types are (`Data`, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
//  public var body: Request.Body?
//
//  /// A dictionary of HTTP headers to be included in the request.
//  public var headers: HTTPHeaders
//
//  /// Initializes a new `Request` instance.
//  /// - Parameters:
//  ///   - url: The URL for the request.
//  ///   - method: The HTTP method for the request. Defaults to "GET".
//  ///   - body: The body of the request. Supported types are (`Data`, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
//  ///   - headers: A dictionary of HTTP headers. Defaults to an empty dictionary.
//  public init(
//    url: URL,
//    method: HTTPMethod = .get,
//    body: Body? = nil,
//    headers: HTTPHeaders = [:]
//  ) {
//    self.url = url
//    self.method = method
//    self.body = body
//    self.headers = headers
//  }

extension HTTPRequest {
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
//}

//extension Request {
//  /// Initializes a new `Request` instance with a string URL.
//  /// - Parameters:
//  ///   - url: A string representation of the URL.
//  ///   - method: The HTTP method for the request. Defaults to "GET".
//  ///   - body: The body of the request. Supported types are (`Data`, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
//  ///   - headers: A dictionary of HTTP headers. Defaults to an empty dictionary.
//  /// - Warning: This initializer force-unwraps the URL. Ensure the URL string is valid.
//  public init(
//    url: String,
//    method: HTTPMethod = .get,
//    body: Body? = nil,
//    headers: HTTPHeaders = [:]
//  ) {
//    self.init(url: URL(string: url)!, method: method, body: body, headers: headers)
//  }
//}

//public struct HTTPMethod: RawRepresentable, Sendable, Hashable, ExpressibleByStringLiteral {
//  public var rawValue: String
//
//  public init(_ rawValue: String) {
//    self.init(rawValue: rawValue)
//  }
//
//  public init(rawValue: String) {
//    self.rawValue = rawValue
//  }
//
//  public init(stringLiteral value: String) {
//    self.init(rawValue: value)
//  }
//
//  public static let get = HTTPMethod("GET")
//  public static let post = HTTPMethod("POST")
//  public static let put = HTTPMethod("PUT")
//  public static let patch = HTTPMethod("PATCH")
//  public static let delete = HTTPMethod("DELETE")
//  public static let head = HTTPMethod("HEAD")
//  public static let options = HTTPMethod("OPTIONS")
//  public static let trace = HTTPMethod("TRACE")
//}
