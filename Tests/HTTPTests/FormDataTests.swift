import Foundation
import InlineSnapshotTesting
import Testing

@testable import HTTP

@Suite struct FormDataTests {

  func makeFormData() -> FormData {
    FormData(boundary: "dev.grds.fetch.boundary.b1c39b05fcb225d1")
  }

  @Test func testAppendStringValue() throws {
    var formData = makeFormData()
    try formData.append("name", "John Doe")

    let encodedData = formData.encode()
    let encodedString = String(data: encodedData, encoding: .utf8)!

    assertInlineSnapshot(of: encodedString, as: .lines) {
      """
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="name"\r
      \r
      John Doe\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1--\r

      """
    }
  }

  @Test func testAppendDataValue() throws {
    var formData = makeFormData()
    let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]).base64EncodedData()  // Mock JPEG data
    try formData.append("image", imageData, filename: "test.jpg")

    let encodedData = formData.encode()
    let encodedString = String(decoding: encodedData, as: UTF8.self)

    assertInlineSnapshot(of: encodedString, as: .lines) {
      """
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="image"; filename="test.jpg"\r
      Content-Type: image/jpeg\r
      \r
      /9j/4A==\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1--\r

      """
    }
  }

  @Test func testAppendMultipleValues() throws {
    var formData = makeFormData()
    try formData.append("key1", "value1")
    try formData.append("key2", "value2")

    let encodedData = formData.encode()
    let encodedString = String(data: encodedData, encoding: .utf8)!

    assertInlineSnapshot(of: encodedString, as: .lines) {
      """
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="key1"\r
      \r
      value1\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="key2"\r
      \r
      value2\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1--\r

      """
    }
  }

  @Test func testContentType() {
    let formData = FormData()
    #expect(formData.contentType.starts(with: "multipart/form-data; boundary="))
  }

  @Test func testEncodingWithCustomValue() throws {
    var formData = makeFormData()
    try formData.append("custom", CustomValue(id: 123, name: "Test"))

    let encodedData = formData.encode()
    let encodedString = String(data: encodedData, encoding: .utf8)!

    assertInlineSnapshot(of: encodedString, as: .lines) {
      """
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="custom"\r
      \r
      {"id":123,"name":"Test"}\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1--\r

      """
    }
  }

  @Test func testEncodingWithHTTPRequestEncodableBodyValue() throws {
    var formData = makeFormData()
    try formData.append("custom", CustomRequestEncodableBody(id: 123, customProperty: "Test"))

    let encodedData = formData.encode()
    let encodedString = String(decoding: encodedData, as: UTF8.self)

    assertInlineSnapshot(of: encodedString, as: .lines) {
      """
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="custom"\r
      \r
      {"custom_property":"Test","id":123}\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1--\r

      """
    }
  }

  @Test func testEncodingWithURLSearchParams() throws {
    var formData = makeFormData()
    try formData.append("params", URLSearchParams("foo=bar&baz=foo"))

    let encodedData = formData.encode()
    let encodedString = String(data: encodedData, encoding: .utf8)!

    assertInlineSnapshot(of: encodedString, as: .lines) {
      """
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="params"\r
      \r
      foo=bar&baz=foo\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1--\r

      """
    }
  }

  @Test func testFormDataDecoding() throws {
    // Create a FormData instance with known content
    var originalForm = makeFormData()
    try originalForm.append("name", "John Doe")
    try originalForm.append("email", "john@example.com")

    // Encode it
    let encodedData = originalForm.encode()
    let contentType = originalForm.contentType

    // Decode it back
    let decodedForm = try FormData.decode(from: encodedData, contentType: contentType)

    // Encode the decoded form to verify contents match
    let reEncodedData = decodedForm.encode()
    let decodedString = String(data: reEncodedData, encoding: .utf8)!

    assertInlineSnapshot(of: decodedString, as: .lines) {
      """
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="name"\r
      \r
      John Doe\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="email"\r
      \r
      john@example.com\r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1--\r

      """
    }
  }

  @Test func testFormDataDecodingWithBinaryContent() throws {
    // Create binary data
    let binaryData = Data((0...255).map { UInt8($0) })

    // Create a FormData instance with binary content
    var originalForm = FormData()
    try originalForm.append(
      "file", binaryData, filename: "test.bin", contentType: "application/octet-stream")

    // Encode it
    let encodedData = originalForm.encode()
    let contentType = originalForm.contentType

    // Decode it back
    let decodedForm = try FormData.decode(from: encodedData, contentType: contentType)

    // Verify the decoded data matches the original
    let decodedPart = decodedForm.bodyParts.first
    #expect(decodedPart != nil)
    #expect(decodedPart?.headers[.contentType] == "application/octet-stream")
    #expect(decodedPart?.headers[.contentDisposition]?.contains(#"filename="test.bin""#) == true)
    #expect(decodedPart?.data == binaryData)
  }

  @Test func formDataWithURLValue() throws {
    var formData = makeFormData()

    let fileURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("Fixtures/file.txt")
    try formData.append("file", fileURL)

    let string = String(decoding: formData.encode(), as: UTF8.self)

    assertInlineSnapshot(of: string, as: .lines) {
      """
      --dev.grds.fetch.boundary.b1c39b05fcb225d1\r
      Content-Disposition: form-data; name="file"; filename="file.txt"\r
      Content-Type: text/plain\r
      \r
      Hello World!
      \r
      --dev.grds.fetch.boundary.b1c39b05fcb225d1--\r

      """
    }
  }

  struct CustomValue: Encodable {
    let id: Int
    let name: String
  }

  struct CustomRequestEncodableBody: HTTPRequestEncodableBody {
    let id: Int
    let customProperty: String

    static let encoder: JSONEncoder = {
      let encoder = JSONEncoder()
      encoder.keyEncodingStrategy = .convertToSnakeCase
      encoder.outputFormatting = [.sortedKeys]
      return encoder
    }()
  }
}
