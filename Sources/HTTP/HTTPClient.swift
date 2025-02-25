import Foundation
@_exported import HTTPTypes
@_exported import HTTPTypesFoundation

/// A type for making HTTP requests with an intuitive API inspired by the web Fetch API.
public protocol HTTPClient: Sendable {
  @discardableResult
  func send(_ request: HTTPRequest, body: Any?) async throws -> Response
}

extension HTTPClient {
  /// Performs an HTTP request with a string URL.
  /// - Parameters:
  ///   - url: The URL string for the request.
  ///   - method: The HTTP method to use for the request.
  ///   - body: The body of the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails or if the URL is invalid.
  ///
  /// Example:
  /// ```swift
  /// do {
  ///     let response = try await http.send("https://api.example.com/data", method: .post, body: ["key": "value"])
  ///     print("Status: \(response.status)")
  ///     let data: MyDataType = try await response.json()
  ///     print("Received data: \(data)")
  /// } catch {
  ///     print("Error: \(error)")
  /// }
  /// ```
  @discardableResult
  public func send(
    _ url: String,
    method: HTTPRequest.Method = .get,
    body: Any? = nil,
    headers: HTTPFields = [:]
  ) async throws -> Response {
    try await self.send(
      URL(string: url)!,
      method: method,
      body: body,
      headers: headers
    )
  }

  /// Performs an HTTP request with a URL object.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - method: The HTTP method to use for the request.
  ///   - body: The body of the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  ///
  /// Example:
  /// ```swift
  /// let url = URL(string: "https://api.example.com/data")!
  /// do {
  ///     let response = try await http.send(url, method: .post, body: ["key": "value"])
  ///     print("Status: \(response.status)")
  ///     let responseText = await response.text()
  ///     print("Response: \(responseText)")
  /// } catch {
  ///     print("Error: \(error)")
  /// }
  /// ```
  @discardableResult
  public func send(
    _ url: URL,
    method: HTTPRequest.Method = .get,
    body: Any? = nil,
    headers: HTTPFields = [:]
  ) async throws -> Response {
    try await self.send(
      HTTPRequest(method: method, url: url, headerFields: headers),
      body: body
    )
  }

  /// Performs a GET request with a URL object.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func get(_ url: URL, headers: HTTPFields = [:]) async throws -> Response {
    try await self.send(url, method: .get, headers: headers)
  }

  /// Performs a GET request with a string URL.
  /// - Parameters:
  ///   - url: The URL string for the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func get(_ url: String, headers: HTTPFields = [:]) async throws -> Response {
    try await self.send(URL(string: url)!, method: .get, headers: headers)
  }

  /// Performs a POST request with a string URL.
  /// - Parameters:
  ///   - url: The URL string for the request.
  ///   - body: The body of the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func post(_ url: String, body: Any? = nil, headers: HTTPFields = [:]) async throws
    -> Response
  {
    try await self.send(URL(string: url)!, method: .post, body: body, headers: headers)
  }

  /// Performs a POST request with a URL object.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - body: The body of the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func post(_ url: URL, body: Any? = nil, headers: HTTPFields = [:]) async throws
    -> Response
  {
    try await self.send(url, method: .post, body: body, headers: headers)
  }

  /// Performs a PUT request with a string URL.
  /// - Parameters:
  ///   - url: The URL string for the request.
  ///   - body: The body of the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func put(_ url: String, body: Any? = nil, headers: HTTPFields = [:]) async throws
    -> Response
  {
    try await self.send(URL(string: url)!, method: .put, body: body, headers: headers)
  }

  /// Performs a PUT request with a URL object.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - body: The body of the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func put(_ url: URL, body: Any? = nil, headers: HTTPFields = [:]) async throws
    -> Response
  {
    try await self.send(url, method: .put, body: body, headers: headers)
  }

  /// Performs a PATCH request with a string URL.
  /// - Parameters:
  ///   - url: The URL string for the request.
  ///   - body: The body of the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func patch(_ url: String, body: Any? = nil, headers: HTTPFields = [:]) async throws
    -> Response
  {
    try await self.send(URL(string: url)!, method: .patch, body: body, headers: headers)
  }

  /// Performs a PATCH request with a URL object.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - body: The body of the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func patch(_ url: URL, body: Any? = nil, headers: HTTPFields = [:]) async throws
    -> Response
  {
    try await self.send(url, method: .patch, body: body, headers: headers)
  }

  /// Performs a DELETE request with a string URL.
  /// - Parameters:
  ///   - url: The URL string for the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func delete(_ url: String, headers: HTTPFields = [:]) async throws -> Response {
    try await self.send(URL(string: url)!, method: .delete, headers: headers)
  }

  /// Performs a DELETE request with a URL object.
  /// - Parameters:
  ///   - url: The URL for the request.
  ///   - headers: The headers of the request.
  /// - Returns: A `Response` object.
  /// - Throws: An error if the request fails.
  @discardableResult
  public func delete(_ url: URL, headers: HTTPFields = [:]) async throws -> Response {
    try await self.send(url, method: .delete, headers: headers)
  }
}
