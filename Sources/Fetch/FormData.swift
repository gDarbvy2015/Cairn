import Foundation

/// A structure for creating and encoding multipart/form-data content.
/// This is commonly used for file uploads and complex form submissions in HTTP requests.
public struct FormData: Sendable {
  private let boundary: String
  private var bodyParts: [BodyPart] = []

  /// Initializes a new FormData instance with a random boundary.
  /// The boundary is used to separate different parts of the multipart form data.
  public init() {
    self.boundary = "dev.grds.fetch.boundary-\(UUID().uuidString)"
  }

  /// Adds a new part to the multipart form data.
  /// - Parameters:
  ///   - name: The name of the form field.
  ///   - value: The value of the form field. Can be a String, Data, or any other type.
  ///   - filename: An optional filename for file uploads. If provided, it will be included in the Content-Disposition header.
  ///   - contentType: An optional MIME type for the part. If provided, it will be included as a Content-Type header.
  /// - Note: If the value is not a String or Data, it will be converted to a String using String(describing:).
  public mutating func append(
    _ name: String,
    _ value: Any,
    filename: String? = nil,
    contentType: String? = nil
  ) {
    let headers = createHeaders(name: name, filename: filename, contentType: contentType)
    let data: Data

    switch value {
    case let string as String:
      data = string.data(using: .utf8)!
    case let d as Data:
      data = d
    default:
      data = String(describing: value).data(using: .utf8)!
    }

    let bodyPart = BodyPart(headers: headers, data: data)
    bodyParts.append(bodyPart)
  }

  /// Encodes the multipart form data into a single Data object.
  /// This method combines all added parts with appropriate headers and boundaries.
  /// - Returns: A Data object containing the encoded multipart form data.
  public func encode() -> Data {
    var data = Data()

    for bodyPart in bodyParts {
      data.append("--\(boundary)\r\n".data(using: .utf8)!)
      for (key, value) in bodyPart.headers {
        data.append("\(key): \(value)\r\n".data(using: .utf8)!)
      }
      data.append("\r\n".data(using: .utf8)!)
      data.append(bodyPart.data)
      data.append("\r\n".data(using: .utf8)!)
    }

    data.append("--\(boundary)--\r\n".data(using: .utf8)!)
    return data
  }

  /// Returns the Content-Type header value for this multipart form data.
  /// This should be used as the Content-Type header when sending the form data in an HTTP request.
  public var contentType: String {
    "multipart/form-data; boundary=\(boundary)"
  }

  private func createHeaders(
    name: String,
    filename: String?,
    contentType: String?
  ) -> [String: String] {
    var headers: [String: String] = [:]

    var disposition = "form-data; name=\"\(name)\""
    if let filename = filename {
      disposition += "; filename=\"\(filename)\""
    }
    headers["Content-Disposition"] = disposition

    if let contentType = contentType {
      headers["Content-Type"] = contentType
    }

    return headers
  }

  private struct BodyPart {
    let headers: [String: String]
    let data: Data
  }
}
