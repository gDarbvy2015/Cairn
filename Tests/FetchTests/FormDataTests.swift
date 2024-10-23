import Foundation
import Testing

@testable import Fetch

@Test func testAppendStringValue() throws {
  var formData = FormData()
  try formData.append("name", "John Doe")

  let encodedData = formData.encode()
  let encodedString = String(data: encodedData, encoding: .utf8)!

  #expect(encodedString.contains("name=\"name\""))
  #expect(encodedString.contains("John Doe"))
}

@Test func testAppendDataValue() throws {
  var formData = FormData()
  let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])  // Mock JPEG data
  try formData.append("image", imageData, filename: "test.jpg", contentType: "image/jpeg")

  let encodedData = formData.encode()
  let encodedString = String(data: encodedData, encoding: .utf8)!

  #expect(encodedString.contains("name=\"image\""))
  #expect(encodedString.contains("filename=\"test.jpg\""))
  #expect(encodedString.contains("Content-Type: image/jpeg"))
}

@Test func testAppendMultipleValues() throws {
  var formData = FormData()
  try formData.append("key1", "value1")
  try formData.append("key2", "value2")

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
  try formData.append("custom", CustomValue(id: 123, name: "Test"))

  let encodedData = formData.encode()
  let encodedString = String(data: encodedData, encoding: .utf8)!

  #expect(encodedString.contains("name=\"custom\""))
  #expect(encodedString.contains(#"{"id":123,"name":"Test"}"#))
}

@Test func testEncodingWithURLSearchParams() throws {
  var formData = FormData()
  try formData.append("params", URLSearchParams("foo=bar&baz=foo"))

  let encodedData = formData.encode()
  let encodedString = String(data: encodedData, encoding: .utf8)!

  #expect(encodedString.contains("name=\"params\""))
  #expect(encodedString.contains("foo=bar&baz=foo"))
}

struct CustomValue: Encodable {
  let id: Int
  let name: String
}
