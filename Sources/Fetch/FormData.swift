import Foundation

/// A structure for creating and encoding multipart/form-data content.
/// This is commonly used for file uploads and complex form submissions in HTTP requests.
public struct FormData: Sendable {
  private var boundary: String
  var bodyParts: [BodyPart] = []

  /// Initializes a new FormData instance with a random boundary.
  /// The boundary is used to separate different parts of the multipart form data.
  public init() {
    let first = UInt32.random(in: UInt32.min...UInt32.max)
    let second = UInt32.random(in: UInt32.min...UInt32.max)
    self.boundary = String(format: "dev.grds.fetch.boundary.%08x%08x", first, second)
  }

  /// Adds a new part to the multipart form data.
  /// - Parameters:
  ///   - name: The name of the form field.
  ///   - value: The value of the form field. Can be a String, Data, URL, URLSearchParams, or any other type that can be encoded to Data.
  ///   - filename: An optional filename for file uploads. If provided, it will be included in the Content-Disposition header.
  ///   - contentType: An optional MIME type for the part. If provided, it will be included as a Content-Type header.
  /// - Throws: An error if the value cannot be converted to Data or if the value type is not supported.
  public mutating func append(
    _ name: String,
    _ value: Any,
    filename: String? = nil,
    contentType: String? = nil
  ) throws {
    let headers = createHeaders(name: name, filename: filename, contentType: contentType)
    let data: Data

    switch value {
    case let d as Data:
      data = d
    case let str as String:
      data = Data(str.utf8)
    case let url as URL:
      data = try Data(contentsOf: url)
    case let searchParams as URLSearchParams:
      data = Data(searchParams.description.utf8)
    default:
      if JSONSerialization.isValidJSONObject(value) {
        data = try JSONSerialization.data(withJSONObject: value)
      } else if let value = value as? any Encodable {
        data = try Fetch.encoder.encode(value)
      } else {
        throw UnsupportedBodyTypeError(type: type(of: value))
      }
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

  struct BodyPart {
    let headers: [String: String]
    let data: Data
  }
}

extension FormData {
  /// Decodes a FormData instance from raw multipart form data.
  /// - Parameters:
  ///   - data: The raw multipart form data to decode
  ///   - contentType: The Content-Type header value containing the boundary
  /// - Returns: A decoded FormData instance
  /// - Throws: An error if the data cannot be decoded or is malformed
  static func decode(from data: Data, contentType: String) throws -> FormData {
    // Extract boundary from content type
    guard let boundary = contentType.components(separatedBy: "boundary=").last else {
      throw FormDataError.missingBoundary
    }

    // Create FormData instance with the extracted boundary
    var formData = FormData()
    formData.boundary = boundary

    // Convert boundary to Data for binary search
    let boundaryData = "--\(boundary)".data(using: .utf8)!
    let crlfData = "\r\n".data(using: .utf8)!
    let doubleCrlfData = "\r\n\r\n".data(using: .utf8)!

    // Find all boundary positions
    var currentIndex = data.startIndex
    var parts: [(start: Int, end: Int)] = []
    while let boundaryRange = data[currentIndex...].range(of: boundaryData) {
        let partStart = boundaryRange.endIndex
        currentIndex = partStart
        
        // Skip if this is the final boundary
        if let dashRange = data[currentIndex...].range(of: "--".data(using: .utf8)!) {
            if dashRange.lowerBound == currentIndex {
                break
            }
        }
        
        // Find the next boundary
        if let nextBoundaryRange = data[currentIndex...].range(of: boundaryData) {
            let partEnd = nextBoundaryRange.lowerBound - crlfData.count
            if partStart < partEnd {
                parts.append((start: partStart, end: partEnd))
            }
            currentIndex = nextBoundaryRange.lowerBound
        }
    }

    // Process each part
    for part in parts {
        let partData = data[part.start..<part.end]
        
        // Find headers section
        guard let headersSeparator = partData.range(of: doubleCrlfData) else { continue }
        let headersData = partData[..<headersSeparator.lowerBound]
        
        // Parse headers (headers are always UTF-8)
        guard let headersString = String(data: headersData, encoding: .utf8) else { continue }
        var headers: [String: String] = [:]
        
        let headerLines = headersString.components(separatedBy: "\r\n")
        for line in headerLines {
            let headerParts = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard headerParts.count == 2 else { continue }
            headers[headerParts[0].trimmingCharacters(in: .whitespaces)] =
                headerParts[1].trimmingCharacters(in: .whitespaces)
        }

        // Extract content (binary data)
        let contentStart = headersSeparator.upperBound
        let contentData = partData[contentStart...]
        
        // Create body part with raw data
        let bodyPart = BodyPart(headers: headers, data: Data(contentData))
        formData.bodyParts.append(bodyPart)
    }

    return formData
  }
}

/// Errors that can occur during FormData operations
enum FormDataError: Error {
  case missingBoundary
  case invalidEncoding
  case malformedContent
}
