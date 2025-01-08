import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

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

  /// Decodes the response body as a JSON.
  public func json() async throws -> Any {
    try await JSONSerialization.jsonObject(with: body.collect())
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

  public static func bytes(_ bytes: [UInt8]) -> Self {
    .data(Data(bytes))
  }
}

public protocol Fetcher: Sendable {
  @discardableResult
  func callAsFunction(
    _ request: Request,
    onUploadProgress: (@Sendable (Progress) -> Void)?
  ) async throws -> Response
}

extension Fetcher {
  @discardableResult
  public func callAsFunction(
    _ request: Request
  ) async throws -> Response {
    try await callAsFunction(request, onUploadProgress: nil)
  }
}

/// A global instance of `Fetch` for convenience.
public let fetch = Fetch()

extension Fetcher {
  /// Performs an HTTP request with a string URL.
  /// - Parameters:
  ///   - url: The URL string for the request.
  ///   - options: Optional `RequestOptions` for the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails or if the URL is invalid.
  ///
  /// Example:
  /// ```swift
  /// do {
  ///     let response = try await fetch("https://api.example.com/data")
  ///     print("Status: \(response.status)")
  ///     let data: MyDataType = try await response.json()
  ///     print("Received data: \(data)")
  /// } catch {
  ///     print("Error: \(error)")
  /// }
  /// ```
  @discardableResult
  public func callAsFunction(
    _ url: String,
    options: RequestOptions? = nil,
    onUploadProgress: (@Sendable (Progress) -> Void)? = nil
  ) async throws -> Response {
    try await self.callAsFunction(
      URL(string: url)!,
      options: options,
      onUploadProgress: onUploadProgress
    )
  }

  /// Performs an HTTP request with a URL object.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - options: Optional `RequestOptions` for the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  ///
  /// Example:
  /// ```swift
  /// let url = URL(string: "https://api.example.com/data")!
  /// let options = RequestOptions(method: "POST", body: ["key": "value"])
  /// do {
  ///     let response = try await fetch(url, options: options)
  ///     print("Status: \(response.status)")
  ///     let responseText = await response.text()
  ///     print("Response: \(responseText)")
  /// } catch {
  ///     print("Error: \(error)")
  /// }
  /// ```
  @discardableResult
  public func callAsFunction(
    _ url: URL,
    options: RequestOptions? = nil,
    onUploadProgress: (@Sendable (Progress) -> Void)? = nil
  ) async throws -> Response {
    try await self.callAsFunction(
      Request(url: url, options: options),
      onUploadProgress: onUploadProgress
    )
  }
}

/// A type for making HTTP requests with an intuitive API inspired by the web Fetch API.
public actor Fetch: Fetcher {
  /// Configuration options for the Fetch instance.
  public struct Configuration {
    /// The `URLSessionConfiguration` to use for network requests.
    public var sessionConfiguration: URLSessionConfiguration
    /// An optional `URLSessionDelegate` for advanced session management.
    public var sessionDelegate: URLSessionDelegate?
    /// An optional `OperationQueue` for handling delegate calls.
    public var sessionDelegateQueue: OperationQueue?
    /// The `JSONEncoder` to use for encoding request bodies.
    public var encoder: JSONEncoder

    /// The default configuration.
    public static var `default`: Configuration {
      Configuration(sessionConfiguration: .default, encoder: Fetch.encoder)
    }
  }

  /// The `URLSession` used for making network requests.
  let session: URLSession

  /// The `JSONEncoder` used for encoding request bodies.
  let encoder: JSONEncoder

  let dataLoader = DataLoader()

  /// Initializes a new `Fetch` instance with the given configuration.
  /// - Parameter configuration: The configuration to use for this Fetch instance.
  ///
  /// Example:
  /// ```swift
  /// let customConfig = Fetch.Configuration(sessionConfiguration: .ephemeral, encoder: JSONEncoder())
  /// let customFetch = Fetch(configuration: customConfig)
  /// ```
  public init(configuration: Configuration = .default) {
    self.session = URLSession(
      configuration: configuration.sessionConfiguration,
      delegate: dataLoader,
      delegateQueue: configuration.sessionDelegateQueue ?? .serial()
    )
    self.encoder = configuration.encoder

    dataLoader.userSessionDelegate = configuration.sessionDelegate
  }

  /// The global `JSONEncoder` instance used by `Fetch`.
  public static var encoder = JSONEncoder()

  /// The global `JSONDecoder` instance used by `Fetch`.
  public static var decoder = JSONDecoder()

  /// Performs an HTTP request using a Request object.
  /// - Parameter request: The `Request` object containing the URL and options.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails or if the response is not an HTTP response.
  ///
  /// Example:
  /// ```swift
  /// let request = Request(url: "https://api.example.com/upload", options: RequestOptions(method: "POST", body: FormData()))
  /// do {
  ///     let response = try await fetch(request)
  ///     if response.ok {
  ///         print("Upload successful")
  ///     } else {
  ///         print("Upload failed with status: \(response.status)")
  ///     }
  /// } catch {
  ///     print("Error: \(error)")
  /// }
  /// ```
  @discardableResult
  public func callAsFunction(
    _ request: Request,
    onUploadProgress: (@Sendable (Progress) -> Void)? = nil
  ) async throws -> Response {
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.options?.method
    urlRequest.allHTTPHeaderFields = request.options?.headers

    if let body = request.options?.body {
      if let url = body as? URL {
        let task = session.uploadTask(with: urlRequest, fromFile: url)
        return try await dataLoader.startUploadTask(
          task, session: session, delegate: nil, onUploadProgress: onUploadProgress)
      } else {
        let uploadData = try encode(body, in: &urlRequest)
        if let uploadData {
          let task = session.uploadTask(with: urlRequest, from: uploadData)
          return try await dataLoader.startUploadTask(
            task, session: session, delegate: nil, onUploadProgress: onUploadProgress)
        } else if urlRequest.httpBodyStream != nil {
          let task = session.dataTask(with: urlRequest)
          return try await dataLoader.startDataTask(
            task,
            session: session,
            delegate: nil,
            onUploadProgress: onUploadProgress
          )
        } else {
          fatalError("Bad request")
        }
      }
    } else {
      let task = session.dataTask(with: urlRequest)
      return try await dataLoader.startDataTask(
        task, session: session, delegate: nil, onUploadProgress: onUploadProgress)
    }
  }

  /// Encodes the request body based on its type.
  /// - Parameters:
  ///   - value: The value to encode as the request body.
  ///   - request: The `URLRequest` to modify with the encoded body.
  /// - Throws: An error if encoding fails or if the value type is not supported.
  private func encode(_ value: Any, in request: inout URLRequest) throws -> Data? {
    switch value {
    case let data as Data:
      return data

    case let str as String:
      return str.data(using: .utf8)!

    case let arr as [UInt8]:
      return Data(arr)

    case let url as URL:
      return try Data(contentsOf: url)

    case let stream as InputStream:
      request.httpBodyStream = stream
      return nil

    case let formData as FormData:
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
      }
      return formData.encode()

    case let searchParams as URLSearchParams:
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      }
      return searchParams.description.data(using: .utf8)!

    default:
      if JSONSerialization.isValidJSONObject(value) {
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return try JSONSerialization.data(withJSONObject: value)
      } else if let value = value as? any Encodable {
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return try encoder.encode(value)
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

extension OperationQueue {
  static func serial() -> OperationQueue {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    return queue
  }
}

public struct Progress {
  public var totalUnitCount: Int64
  public var sentUnitCount: Int64

  public var fractionCompleted: Double {
    Double(sentUnitCount) / Double(totalUnitCount)
  }
}

final class _Delegate: NSObject, URLSessionTaskDelegate {
  private let didCompleteTask: (@Sendable (URLSession, URLSessionTask) -> Void)?

  init(didCompleteTask: (@Sendable (URLSession, URLSessionTask) -> Void)?) {
    self.didCompleteTask = didCompleteTask
  }

  func urlSession(_ session: URLSession, didCompleteTask task: URLSessionTask) {
    didCompleteTask?(session, task)
  }
}
