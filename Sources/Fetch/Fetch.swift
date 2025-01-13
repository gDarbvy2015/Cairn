import Foundation

/// A type for making HTTP requests with an intuitive API inspired by the web Fetch API.
public protocol Fetch: Sendable {
  @discardableResult
  func callAsFunction(
    _ request: Request
  ) async throws -> Response
}

extension Fetch {
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
