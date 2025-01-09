import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public protocol Fetcher: Sendable {
  @discardableResult
  func callAsFunction(
    _ request: Request
  ) async throws -> Response
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
    options: RequestOptions? = nil
  ) async throws -> Response {
    try await self.callAsFunction(
      URL(string: url)!,
      options: options
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
    options: RequestOptions? = nil
  ) async throws -> Response {
    try await self.callAsFunction(
      Request(url: url, options: options)
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
    _ request: Request
  ) async throws -> Response {
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.options?.method
    urlRequest.allHTTPHeaderFields = request.options?.headers

    if let body = request.options?.body {
      if let url = body as? URL {
        let task = session.uploadTask(with: urlRequest, fromFile: url)
        return try await dataLoader.startUploadTask(
          task, session: session, delegate: nil)
      } else {
        let uploadData = try encode(body, in: &urlRequest)
        if let uploadData {
          let task = session.uploadTask(with: urlRequest, from: uploadData)
          return try await dataLoader.startUploadTask(
            task, session: session, delegate: nil)
        } else if urlRequest.httpBodyStream != nil {
          let task = session.dataTask(with: urlRequest)
          return try await dataLoader.startDataTask(
            task,
            session: session,
            delegate: nil
          )
        } else {
          fatalError("Bad request")
        }
      }
    } else {
      let task = session.dataTask(with: urlRequest)
      return try await dataLoader.startDataTask(
        task,
        session: session,
        delegate: nil
      )
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
