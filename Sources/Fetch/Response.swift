//
//  Response.swift
//  Fetch
//
//  Created by Guilherme Souza on 08/01/25.
//

import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Represents an HTTP response.
public struct Response: Sendable {
  /// The URL of the response.
  public let url: URL

  /// The body of the response.
  public let body: Body

  /// A dictionary of HTTP headers received in the response.
  public let headers: [String: String]

  /// The HTTP status code of the response.
  public let status: Int

  /// The HTTP status text of the response.
  public var statusText: String {
    HTTPURLResponse.localizedString(forStatusCode: status)
  }

  /// Indicates whether the response status code is in the successful range (200-299).
  public var ok: Bool {
    200..<300 ~= status
  }

  /// Converts the response body to a string.
  /// - Returns: The response body as a UTF-8 encoded string.
  public func text() async -> String {
    await String(decoding: body.collect(), as: UTF8.self)
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
      return try await (decoder ?? Fetch.decoder).decode(type, from: body.collect())
    }
  }

  /// Decodes the response body as a JSON using `JSONSerialization`.
  public func json() async throws -> Any {
    try await JSONSerialization.jsonObject(with: body.collect())
  }

  /// Decodes response body as a ``FormData``.
  public func formData() async throws -> FormData {
    try await FormData.decode(from: body.collect(), contentType: headers["Content-Type"] ?? "")
  }

  /// Decodes response as ``Data``.
  public func data() async -> Data {
    await body.collect()
  }

  public struct Body: AsyncSequence, Sendable {
    public typealias AsyncIterator = AsyncStream<Data>.Iterator
    public typealias Element = Data
    public typealias Failure = Never

    let stream: AsyncStream<Data>
    let continuation: AsyncStream<Data>.Continuation

    init() {
      (stream, continuation) = AsyncStream.makeStream()
    }

    public func makeAsyncIterator() -> AsyncIterator {
      stream.makeAsyncIterator()
    }

    public func collect() async -> Data {
      await stream.reduce(into: Data()) { $0 += $1 }
    }

    func append(_ data: Data) {
      continuation.yield(data)
    }

    func finalize() {
      continuation.finish()
    }
  }
}

extension Response.Body {
  public static func string(_ string: String, using encoding: String.Encoding = .utf8) -> Self {
    let body = Self()
    body.append(string.data(using: encoding)!)
    body.finalize()
    return body
  }

  public static func data(_ data: Data) -> Self {
    let body = Self()
    body.append(data)
    body.finalize()
    return body
  }
}
