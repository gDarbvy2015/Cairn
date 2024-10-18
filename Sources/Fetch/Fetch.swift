import Foundation

/// Represents options for an HTTP request.
public struct RequestOptions: @unchecked Sendable {
  /// The HTTP method for the request (e.g., "GET", "POST", "PUT", etc.).
  public let method: String

  /// The body of the request. Supported types are (`Data`, `[UInt8]`, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
  public let body: Any?

  /// A dictionary of HTTP headers to be included in the request.
  public let headers: [String: String]

  /// Initializes a new `RequestOptions` instance.
  /// - Parameters:
  ///   - method: The HTTP method for the request. Defaults to "GET".
  ///   - body: The body of the request. Supported types are (`Data`, `[UInt8]`, `String`, `FormData`, `URLSearchParams`, `any valid JSON object`, `any Encodable`).
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
  public let url: URL

  /// Optional `RequestOptions` for the request.
  public let options: RequestOptions?

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

/// Represents an HTTP response.
public struct Response: Sendable {
  /// The URL of the response.
  public let url: URL

  /// The body of the response as raw data.
  public let body: Data

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
    await Task.detached {
      String(decoding: body, as: UTF8.self)
    }.value
  }

  /// Decodes the response body to a specified type.
  /// - Parameters:
  ///   - type: The type to decode the JSON into.
  ///   - decoder: The JSON decoder to use. Defaults to global `Fetch.decoder`.
  /// - Returns: The decoded object of type `T`.
  /// - Throws: An error if decoding fails.
  public func json<T: Decodable & Sendable>(
    as type: T.Type,
    decoder: JSONDecoder? = nil
  ) async throws -> T {
    try await Task.detached {
      try (decoder ?? Fetch.decoder).decode(type, from: body)
    }.value
  }
}

/// A global instance of `Fetch` for convenience.
public let fetch = Fetch()

/// A structure for making HTTP requests.
public struct Fetch: Sendable {
  /// The `URLSession` used for making network requests.
  let session: URLSession

  /// The `JSONEncoder` used for encoding request bodies.
  let encoder: JSONEncoder

  /// Initializes a new `Fetch` instance.
  /// - Parameters:
  ///   - session: The `URLSession` to use for requests. Defaults to `.shared`.
  ///   - encoder: The `JSONEncoder` to use for encoding request bodies. Defaults to `Fetch.encoder`.
  public init(session: URLSession = .shared, encoder: JSONEncoder = Fetch.encoder) {
    self.session = session
    self.encoder = encoder
  }

  /// Lock for synchronizing access to global static variables.
  private static let staticLock = NSLock()

  nonisolated(unsafe) private static var _encoder = JSONEncoder()
  nonisolated(unsafe) private static var _decoder = JSONDecoder()

  /// The global `JSONEncoder` instance used by `Fetch`.
  public static var encoder: JSONEncoder {
    get { staticLock.withLock { _encoder } }
    set { staticLock.withLock { _encoder = newValue } }
  }

  /// The global `JSONDecoder` instance used by `Fetch`.
  public static var decoder: JSONDecoder {
    get { staticLock.withLock { _decoder } }
    set { staticLock.withLock { _decoder = newValue } }
  }

  /// Performs an HTTP request.
  /// - Parameters:
  ///   - url: The URL string for the request.
  ///   - options: Optional `RequestOptions` for the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails or if the URL is invalid.
  @discardableResult
  public func callAsFunction(
    _ url: String,
    options: RequestOptions? = nil
  ) async throws -> Response {
    try await self.callAsFunction(URL(string: url)!, options: options)
  }

  /// Performs an HTTP request.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - options: Optional `RequestOptions` for the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func callAsFunction(
    _ url: URL,
    options: RequestOptions? = nil
  ) async throws -> Response {
    try await self.callAsFunction(Request(url: url, options: options))
  }

  /// Performs an HTTP request.
  /// - Parameter request: The `Request` object containing the URL and options.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails or if the response is not an HTTP response.
  @discardableResult
  public func callAsFunction(_ request: Request) async throws -> Response {
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.options?.method
    urlRequest.allHTTPHeaderFields = request.options?.headers

    if let body = request.options?.body {
      try encode(body, in: &urlRequest)
    }

    let (data, response) = try await session.data(for: urlRequest)

    guard let httpRespnse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    return Response(
      url: httpRespnse.url!,
      body: data,
      headers: httpRespnse.allHeaderFields as? [String: String] ?? [:],
      status: httpRespnse.statusCode
    )
  }

  /// Encodes the request body based on its type.
  /// - Parameters:
  ///   - value: The value to encode as the request body.
  ///   - request: The `URLRequest` to modify with the encoded body.
  /// - Throws: An error if encoding fails or if the value type is not supported.
  private func encode(_ value: Any, in request: inout URLRequest) throws {
    switch value {
    case let data as Data:
      request.httpBody = data

    case let str as String:
      request.httpBody = str.data(using: .utf8)!

    case let arr as [UInt8]:
      request.httpBody = Data(arr)

    case let url as URL:
      request.httpBody = try Data(contentsOf: url)

    case let formData as FormData:
      request.httpBody = formData.encode()
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
      }

    case let searchParams as URLSearchParams:
      request.httpBody = searchParams.description.data(using: .utf8)!
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      }

    default:
      if JSONSerialization.isValidJSONObject(value) {
        request.httpBody = try JSONSerialization.data(withJSONObject: value)
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
      } else if let value = value as? any Encodable {
        request.httpBody = try encoder.encode(value)
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
      } else {
        throw UnsupportedBodyTypeError(type: type(of: value))
      }
    }
  }
}

/// An error thrown when an unsupported body type is provided for the request.
public struct UnsupportedBodyTypeError: Error {
  /// The type of the unsupported body value.
  public let type: Any.Type
}
