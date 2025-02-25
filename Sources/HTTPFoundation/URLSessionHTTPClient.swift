import Foundation
@_exported import HTTP
import HTTPTypes
import HTTPTypesFoundation
import IssueReporting

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A global instance of `Fetch` for convenience.
public let http: any HTTPClient = URLSessionHTTPClient()

/// A ``Fetch`` implementation that uses `URLSession`.
public struct URLSessionHTTPClient: HTTPClient {
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
  public func send(
    _ request: HTTPRequest,
    body: Any?
  ) async throws -> Response {
    var urlRequest = URLRequest(httpRequest: request)!

    if let body {
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
        } else {
          reportIssue("Malformed request")
          return Response(
            httpResponse: HTTPResponse(status: .badRequest),
            body: .data(Data())
          )
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
    _ value: Any,
    in request: inout URLRequest
  ) throws -> Data? {
    switch value {
    case let data as Data:
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
      }
      return data

    case let str as String:
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
      }
      return Data(str.utf8)

    case let url as URL:
      return try Data(contentsOf: url)

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

    case let value as any HTTPRequestEncodableBody:
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }

      return try type(of: value).encoder.encode(value)

    case let value as any Encodable:
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }

      return try (encoder ?? JSONEncoder()).encode(value)

    default:
      if JSONSerialization.isValidJSONObject(value) {
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return try JSONSerialization.data(withJSONObject: value)
      } else {
        reportIssue("Unsupported body type: \(type(of: value))")
        return nil
      }
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
