@_exported import Fetch
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A global instance of `Fetch` for convenience.
public let fetch: any Fetch = URLSessionFetch()

/// A ``Fetch`` implementation that uses `URLSession`.
public struct URLSessionFetch: Fetch {
  /// Configuration options for the Fetch instance.
  public struct Configuration {
    /// The `URLSessionConfiguration` to use for network requests.
    public var sessionConfiguration: URLSessionConfiguration
    /// An optional `URLSessionDelegate` for advanced session management.
    public var sessionDelegate: URLSessionDelegate?
    /// An optional `OperationQueue` for handling delegate calls.
    public var sessionDelegateQueue: OperationQueue?
    /// The `JSONEncoder` to use for encoding request bodies.
    public var encoder: JSONEncoder?

    public init(
      sessionConfiguration: URLSessionConfiguration = .default,
      sessionDelegate: URLSessionDelegate? = nil,
      sessionDelegateQueue: OperationQueue? = nil,
      encoder: JSONEncoder? = nil
    ) {
      self.sessionConfiguration = sessionConfiguration
      self.sessionDelegate = sessionDelegate
      self.sessionDelegateQueue = sessionDelegateQueue
      self.encoder = encoder
    }

    /// The default configuration.
    public static var `default`: Configuration {
      Configuration()
    }
  }

  /// The `URLSession` used for making network requests.
  let session: URLSession

  let encoder: JSONEncoder?

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

  /// Performs an HTTP request using a Request object.
  /// - Parameter request: The `Request` object containing the URL and options.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails or if the response is not an HTTP response.
  ///
  /// Example:
  /// ```swift
  /// let request = Request(url: "https://api.example.com/upload", options: RequestOptions(method: "POST", body: .formData(FormData())))
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
    urlRequest.httpMethod = request.options.method.rawValue
    urlRequest.allHTTPHeaderFields = request.options.headers

    if let body = request.options.body {
      if case .url(let url) = body {
        let task = session.uploadTask(with: urlRequest, fromFile: url)
        return try await dataLoader.startUploadTask(
          task, session: session, delegate: nil)
      } else {
        let uploadData = try encode(body, in: &urlRequest)
        if let uploadData {
          let task = session.uploadTask(with: urlRequest, from: uploadData)
          return try await dataLoader.startUploadTask(
            task, session: session, delegate: nil)
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
  private func encode(
    _ value: Request.Body,
    in request: inout URLRequest
  ) throws -> Data? {
    switch value {
    case let .data(data):
      return data

    case let .string(str, encoding):
      return str.data(using: encoding)!

    case let .url(url):
      return try Data(contentsOf: url)

    case let .formData(formData):
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
      }
      return formData.encode()

    case let .urlSearchParams(searchParams):
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      }
      return searchParams.description.data(using: .utf8)!

    case let .json(value):
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }
      return try JSONSerialization.data(withJSONObject: value)

    case let .encodable(value, encoder):
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }

      return try (encoder ?? self.encoder ?? JSONEncoder()).encode(value)
    }
  }
}

extension OperationQueue {
  static func serial() -> OperationQueue {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    return queue
  }
}
