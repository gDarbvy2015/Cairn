import Foundation

/// A structure for creating and encoding multipart/form-data content.
/// This is commonly used for file uploads and complex form submissions in HTTP requests.
public struct FormData: Sendable {
  private var boundary: String
  var bodyParts: [BodyPart] = []

  /// Initializes a new FormData instance with a random boundary.
  /// The boundary is used to separate different parts of the multipart form data.
  public init(boundary: String? = nil) {
    if let boundary {
      self.boundary = boundary
    } else {
      let first = UInt32.random(in: UInt32.min...UInt32.max)
      let second = UInt32.random(in: UInt32.min...UInt32.max)
      self.boundary = String(format: "dev.grds.fetch.boundary.%08x%08x", first, second)
    }
  }

  /// Adds a new part to the multipart form data.
  /// - Parameters:
  ///   - name: The name of the form field.
  ///   - value: The value of the form field. Supported types include `String`, `Data`, `URL`, `URLSearchParams`, `HTTPRequestEncodableBody`, `Encodable`, or any valid `JSON` object.
  ///   - filename: An optional filename for file uploads. If provided, it will be included in the Content-Disposition header.
  ///   - contentType: An optional MIME type for the part. If provided, it will be included as a Content-Type header.
  /// - Throws: An error if the value cannot be converted to Data or if the value type is not supported.
  /// - Note: If `filename` or `contentType` are not provided, they will be inferred based on the `value` when possible.
  public mutating func append(
    _ name: String,
    _ value: Any,
    filename: String? = nil,
    contentType: String? = nil
  ) throws {
    let data: Data

    var filename = filename
    var contentType = contentType

    switch value {
    case let d as Data:
      data = d
    case let str as String:
      data = Data(str.utf8)
    case let url as URL:
      if contentType == nil {
        contentType = FormData.mimeType(forPathExtension: url.pathExtension)
      }

      if filename == nil {
        filename = url.lastPathComponent
      }

      data = try Data(contentsOf: url)
    case let searchParams as URLSearchParams:
      data = Data(searchParams.description.utf8)
    case let value as any HTTPRequestEncodableBody:
      data = try type(of: value).encoder.encode(value)
    case let value as any Encodable:
      data = try JSONEncoder.default.encode(value)
    default:
      if JSONSerialization.isValidJSONObject(value) {
        data = try JSONSerialization.data(withJSONObject: value)
      } else {
        fatalError("Unsupported value type for form data: \(type(of: value))")
      }
    }

    // no content type provided, try to extract it from the filename.
    if contentType == nil, let filename {
      contentType = FormData.mimeType(forPathExtension: (filename as NSString).pathExtension)
    }

    let headers = createHeaders(
      name: name,
      filename: filename,
      contentType: contentType
    )

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
      for field in bodyPart.headers {
        data.append("\(field.name): \(field.value)\r\n".data(using: .utf8)!)
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
  ) -> HTTPFields {
    var headers = HTTPFields()

    var disposition = "form-data; name=\"\(name)\""
    if let filename = filename {
      disposition += "; filename=\"\(filename)\""
    }
    headers[.contentDisposition] = disposition

    if let contentType = contentType {
      headers[.contentType] = contentType
    }

    return headers
  }

  struct BodyPart {
    let headers: HTTPFields
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
      var headers = HTTPFields()

      let headerLines = headersString.components(separatedBy: "\r\n")
      for line in headerLines {
        let headerParts = line.split(separator: ":", maxSplits: 1).map(String.init)
        guard headerParts.count == 2 else { continue }
        headers[.init(headerParts[0].trimmingCharacters(in: .whitespaces))!] =
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

#if canImport(UniformTypeIdentifiers)
  import UniformTypeIdentifiers

  extension FormData {
    /// Determines the MIME type based on the file extension.
    /// Uses UniformTypeIdentifiers if available, otherwise falls back to CoreServices or MobileCoreServices.
    package static func mimeType(forPathExtension pathExtension: String) -> String {
      if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, visionOS 1, *) {
        return UTType(filenameExtension: pathExtension)?.preferredMIMEType
          ?? "application/octet-stream"
      } else {
        if let id = UTTypeCreatePreferredIdentifierForTag(
          kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
          let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?
            .takeRetainedValue()
        {
          return contentType as String
        }

        return "application/octet-stream"
      }
    }
  }
#else
  extension FormData {
    /// Determines the MIME type based on the file extension.
    /// Uses UniformTypeIdentifiers if available, otherwise falls back to CoreServices or MobileCoreServices.
    package static func mimeType(forPathExtension pathExtension: String) -> String {
      #if canImport(CoreServices) || canImport(MobileCoreServices)
        if let id = UTTypeCreatePreferredIdentifierForTag(
          kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
          let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?
            .takeRetainedValue()
        {
          return contentType as String
        }
      #endif

      return "application/octet-stream"
    }
  }
#endif
