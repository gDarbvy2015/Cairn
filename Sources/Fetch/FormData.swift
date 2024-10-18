import Foundation

/// A structure for creating multipart/form-data content.
public struct FormData: Sendable {
  private let boundary: String
  private var bodyParts: [BodyPart] = []

  /// Initializes a new MultipartFormData instance with a random boundary.
  public init() {
    self.boundary = "Boundary-\(UUID().uuidString)"
  }

  /// Adds a new part to the multipart form data.
  /// - Parameters:
  ///   - name: The name of the form field.
  ///   - value: The value of the form field.
  ///   - filename: An optional filename for file uploads.
  ///   - contentType: An optional content type for the part.
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
      data = string.data(using: .utf8) ?? Data()
    case let d as Data:
      data = d
    default:
      data = String(describing: value).data(using: .utf8) ?? Data()
    }

    let bodyPart = BodyPart(headers: headers, data: data)
    bodyParts.append(bodyPart)
  }

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
  public var contentType: String {
    return "multipart/form-data; boundary=\(boundary)"
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
