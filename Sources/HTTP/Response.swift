//
//  Response.swift
//  Fetch
//
//  Created by Guilherme Souza on 08/01/25.
//

import HTTPTypes

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

#if !canImport(Darwin) || compiler(>=5.9)
  @preconcurrency import Foundation
#else
  import Foundation
#endif

/// Represents an HTTP response.
public struct Response: Sendable {
  /// The HTTP response.
  public var httpResponse: HTTPResponse

  /// The body of the response.
  public let body: Body

  /// The headers of the response.
  public var headers: HTTPFields {
    httpResponse.headerFields
  }

  /// The HTTP status code of the response.
  public var status: HTTPResponse.Status { httpResponse.status }

  public init(httpResponse: HTTPResponse, body: Body) {
    self.httpResponse = httpResponse
    self.body = body
  }

  /// The HTTP status text of the response.
  public var statusText: String {
    status.reasonPhrase
  }

  /// Indicates whether the response status code is in the successful range (200-299).
  public var ok: Bool {
    200..<300 ~= status.code
  }

  /// Converts the response body to a string.
  /// - Returns: The response body as a UTF-8 encoded string.
  public func text() async -> String {
    await String(decoding: body.collect(), as: UTF8.self)
  }

  private static let lock = NSLock()

  #if compiler(>=6)
    nonisolated(unsafe) private static var _decoder = JSONDecoder()
  #else
    private static var _decoder = JSONDecoder()
  #endif

  /// The default decoder instance used in ``decode(as:decoder:)`` method.
  public static var decoder: JSONDecoder {
    get { lock.withLock { _decoder } }
    set { lock.withLock { _decoder = newValue } }
  }

  /// Decodes the response body to a specified type.
  /// - Parameters:
  ///   - type: The type to decode the JSON into.
  ///   - decoder: The JSON decoder to use. Defaults to global `Fetch.decoder`.
  /// - Returns: The decoded object of type `T`.
  /// - Throws: An error if decoding fails.
  public func decode<T: Decodable & Sendable>(
    as type: T.Type = T.self,
    decoder: JSONDecoder? = nil
  ) async throws -> T {
    if T.self is Data.Type {
      return await body.collect() as! T
    } else if T.self is String.Type {
      return await self.text() as! T
    } else {
      return try await (decoder ?? Response.decoder).decode(type, from: body.collect())
    }
  }

  /// Decodes the response body as a JSON using `JSONSerialization`.
  /// - Returns: The response body as a JSON object.
  public func json() async throws -> Any {
    try await JSONSerialization.jsonObject(with: body.collect())
  }

  /// Decodes response body as a ``FormData``.
  /// - Returns: The response body as a ``FormData``.
  public func formData() async throws -> FormData {
    try await FormData.decode(from: body.collect(), contentType: headers[.contentType] ?? "")
  }

  /// Decodes response body as ``Data``.
  /// - Returns: The response body as ``Data``.
  public func data() async -> Data {
    await body.collect()
  }

  /// A type that represents the body of an HTTP response.
  public final class Body: AsyncSequence, Sendable {
    public typealias AsyncIterator = AsyncStream<Data>.Iterator
    public typealias Element = Data
    public typealias Failure = Never

    let stream: AsyncStream<Data>
    let continuation: AsyncStream<Data>.Continuation

    package init() {
      (stream, continuation) = AsyncStream.makeStream()
    }

    public func makeAsyncIterator() -> AsyncIterator {
      stream.makeAsyncIterator()
    }

    /// Collects the response body as a ``Data``.
    /// - Returns: The response body as ``Data``.
    public func collect() async -> Data {
      await stream.reduce(into: Data()) { $0 += $1 }
    }

    package func yield(_ data: Data) {
      continuation.yield(data)
    }

    package func finish() {
      continuation.finish()
    }
  }
}

extension Response.Body {
  /// Creates a new ``Body`` instance with the given string.
  /// - Parameters:
  ///   - string: The string to append to the body.
  /// - Returns: A new ``Body`` instance with the given string.
  public static func string(_ string: String) -> Self {
    let body = Self()
    body.yield(string.data(using: .utf8)!)
    body.finish()
    return body
  }

  /// Creates a new ``Body`` instance with the given data.
  /// - Parameters:
  ///   - data: The data to append to the body.
  /// - Returns: A new ``Body`` instance with the given data.
  public static func data(_ data: Data) -> Self {
    let body = Self()
    body.yield(data)
    body.finish()
    return body
  }

  /// Creates a new ``Body`` instance with the given JSON value.
  /// - Parameters:
  ///   - value: The JSON value to append to the body.
  /// - Returns: A new ``Body`` instance with the given JSON value.
  public static func json(_ value: Any) throws -> Self {
    data(try JSONSerialization.data(withJSONObject: value))
  }

  /// Creates a new ``Body`` instance with the given encodable value.
  /// - Parameters:
  ///   - value: The encodable value to append to the body.
  /// - Returns: A new ``Body`` instance with the given encodable value.
  public static func encodable(_ value: any HTTPRequestEncodableBody) throws -> Self {
    data(try type(of: value).encoder.encode(value))
  }

  /// Creates a new ``Body`` instance with the given encodable value.
  /// - Parameters:
  ///   - value: The encodable value to append to the body.
  /// - Returns: A new ``Body`` instance with the given encodable value.
  public static func encodable(_ value: any Encodable) throws -> Self {
    data(try JSONEncoder().encode(value))
  }
}
