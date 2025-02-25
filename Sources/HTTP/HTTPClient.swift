import Foundation

/// A type for making HTTP requests with an intuitive API inspired by the web Fetch API.
public protocol HTTPClient: Sendable {
  @discardableResult
  func send(_ request: Request) async throws -> Response
}

extension HTTPClient {
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
  public func send(
    _ url: String,
    method: HTTPMethod = .get,
    body: Request.Body? = nil,
    headers: HTTPHeaders = [:]
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
  public func send(
    _ url: URL,
    method: HTTPMethod = .get,
    body: Request.Body? = nil,
    headers: HTTPHeaders = [:]
  ) async throws -> Response {
    try await self.send(
      Request(
        url: url,
        method: method,
        body: body,
        headers: headers
      )
    )
  }

  @discardableResult
  public func get(_ url: URL, headers: HTTPHeaders = [:]) async throws -> Response {
    try await self.send(url, method: .get, headers: headers)
  }

  @discardableResult
  public func get(_ url: String, headers: HTTPHeaders = [:]) async throws -> Response {
    try await self.send(URL(string: url)!, method: .get, headers: headers)
  }

  @discardableResult
  public func post(_ url: String, body: Request.Body?, headers: HTTPHeaders = [:]) async throws
    -> Response
  {
    try await self.send(URL(string: url)!, method: .post, body: body, headers: headers)
  }

  @discardableResult
  public func post(_ url: URL, body: Request.Body?, headers: HTTPHeaders = [:]) async throws
    -> Response
  {
    try await self.send(url, method: .post, body: body, headers: headers)
  }

  @discardableResult
  public func put(_ url: String, body: Request.Body?, headers: HTTPHeaders = [:]) async throws
    -> Response
  {
    try await self.send(URL(string: url)!, method: .put, body: body, headers: headers)
  }

  @discardableResult
  public func put(_ url: URL, body: Request.Body?, headers: HTTPHeaders = [:]) async throws
    -> Response
  {
    try await self.send(url, method: .put, body: body, headers: headers)
  }

  @discardableResult
  public func patch(_ url: String, body: Request.Body?, headers: HTTPHeaders = [:]) async throws
    -> Response
  {
    try await self.send(URL(string: url)!, method: .patch, body: body, headers: headers)
  }

  @discardableResult
  public func patch(_ url: URL, body: Request.Body?, headers: HTTPHeaders = [:]) async throws
    -> Response
  {
    try await self.send(url, method: .patch, body: body, headers: headers)
  }

  @discardableResult
  public func delete(_ url: String, headers: HTTPHeaders = [:]) async throws -> Response {
    try await self.send(URL(string: url)!, method: .delete, headers: headers)
  }

  @discardableResult
  public func delete(_ url: URL, headers: HTTPHeaders = [:]) async throws -> Response {
    try await self.send(url, method: .delete, headers: headers)
  }
}
