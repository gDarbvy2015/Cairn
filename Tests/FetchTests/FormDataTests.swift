import Foundation
import Testing

@testable import HTTP

@Test func testAppendStringValue() throws {
  var formData = FormData()
  try formData.append("name", .string("John Doe"))

  let encodedData = formData.encode()
  let encodedString = String(data: encodedData, encoding: .utf8)!

  #expect(encodedString.contains("name=\"name\""))
  #expect(encodedString.contains("John Doe"))
}

@Test func testAppendDataValue() throws {
  var formData = FormData()
  let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]).base64EncodedData()  // Mock JPEG data
  try formData.append("image", .data(imageData), filename: "test.jpg", contentType: "image/jpeg")

  let encodedData = formData.encode()
  let encodedString = String(decoding: encodedData, as: UTF8.self)

  let expectedImageData = String(decoding: imageData, as: UTF8.self)

  #expect(encodedString.contains("name=\"image\""))
  #expect(encodedString.contains("filename=\"test.jpg\""))
  #expect(encodedString.contains("content-type: image/jpeg"))
  #expect(encodedString.contains(expectedImageData))
}

@Test func testAppendMultipleValues() throws {
  var formData = FormData()
  try formData.append("key1", .string("value1"))
  try formData.append("key2", .string("value2"))

  let encodedData = formData.encode()
  let encodedString = String(data: encodedData, encoding: .utf8)!

  #expect(encodedString.contains("name=\"key1\""))
  #expect(encodedString.contains("value1"))
  #expect(encodedString.contains("name=\"key2\""))
  #expect(encodedString.contains("value2"))
}

@Test func testContentType() {
  let formData = FormData()
  #expect(formData.contentType.starts(with: "multipart/form-data; boundary="))
}

@Test func testEncodingWithCustomValue() throws {
  var formData = FormData()
  try formData.append("custom", .encodable(CustomValue(id: 123, name: "Test")))

  let encodedData = formData.encode()
  let encodedString = String(data: encodedData, encoding: .utf8)!

  #expect(encodedString.contains("name=\"custom\""))
  #expect(encodedString.contains(#""id":123"#))
  #expect(encodedString.contains(#""name":"Test"#))
}

@Test func testEncodingWithURLSearchParams() throws {
  var formData = FormData()
  try formData.append("params", .urlSearchParams(URLSearchParams("foo=bar&baz=foo")))

  let encodedData = formData.encode()
  let encodedString = String(data: encodedData, encoding: .utf8)!

  #expect(encodedString.contains("name=\"params\""))
  #expect(encodedString.contains("foo=bar&baz=foo"))
}

@Test func testFormDataDecoding() throws {
  // Create a FormData instance with known content
  var originalForm = FormData()
  try originalForm.append("name", .string("John Doe"))
  try originalForm.append("email", .string("john@example.com"))

  // Encode it
  let encodedData = originalForm.encode()
  let contentType = originalForm.contentType

  // Decode it back
  let decodedForm = try FormData.decode(from: encodedData, contentType: contentType)

  // Encode the decoded form to verify contents match
  let reEncodedData = decodedForm.encode()
  let decodedString = String(data: reEncodedData, encoding: .utf8)!

  #expect(decodedString.contains("name=\"name\""))
  #expect(decodedString.contains("John Doe"))
  #expect(decodedString.contains("name=\"email\""))
  #expect(decodedString.contains("john@example.com"))
}

@Test func testFormDataDecodingWithBinaryContent() throws {
  // Create binary data
  let binaryData = Data((0...255).map { UInt8($0) })

  // Create a FormData instance with binary content
  var originalForm = FormData()
  try originalForm.append(
    "file", .data(binaryData), filename: "test.bin", contentType: "application/octet-stream")

  // Encode it
  let encodedData = originalForm.encode()
  let contentType = originalForm.contentType

  // Decode it back
  let decodedForm = try FormData.decode(from: encodedData, contentType: contentType)

  // Verify the decoded data matches the original
  let decodedPart = decodedForm.bodyParts.first
  #expect(decodedPart != nil)
  #expect(decodedPart?.headers["Content-Type"] == "application/octet-stream")
  #expect(decodedPart?.headers["Content-Disposition"]?.contains("filename=\"test.bin\"") == true)
  #expect(decodedPart?.data == binaryData)
}

struct CustomValue: Encodable {
  let id: Int
  let name: String
}
