import Foundation
import Testing

@testable import HTTP

@Test func textResponse() async throws {
  let stringResponse = Response(
    httpResponse: HTTPResponse(status: .ok),
    body: .string("string value")
  )

  #expect(await stringResponse.text() == "string value")
}

@Test func decodeStringResponse() async throws {
  let stringResponse = Response(
    httpResponse: HTTPResponse(status: .ok),
    body: .string("string value")
  )

  try #expect(await stringResponse.decode() as String == "string value")
}

@Test func decodeDataResponse() async throws {
  let stringResponse = Response(
    httpResponse: HTTPResponse(status: .ok),
    body: .string("string value")
  )

  try #expect(await stringResponse.decode() as Data == Data("string value".utf8))
}

@Test func decodeJSONResponse() async throws {
  struct JSON: Decodable {
    let value: String
  }

  let response = Response(
    httpResponse: HTTPResponse(status: .ok),
    body: .string(#"{ "value": "string value" }"#)
  )

  let json = try await response.decode() as JSON
  #expect(json.value == "string value")
}

@Test func responseFromHTTPRequestEncodableBody() async throws {
  struct Value: HTTPRequestEncodableBody, Decodable {
    let customKey: String

    static var encoder: JSONEncoder {
      let encoder = JSONEncoder()
      encoder.keyEncodingStrategy = .convertToSnakeCase
      return encoder
    }
  }

  let response = Response(
    httpResponse: HTTPResponse(status: .ok),
    body: try .encodable(Value(customKey: "string value"))
  )

  let json = try await response.json() as? [String: String]
  #expect(json?["custom_key"] == "string value")
}

@Test func responseFromEncodable() async throws {
  struct Value: Encodable {
    let customKey: String
  }

  let response = Response(
    httpResponse: HTTPResponse(status: .ok),
    body: try .encodable(Value(customKey: "string value"))
  )

  let json = try await response.json() as? [String: String]
  #expect(json?["customKey"] == "string value")
}
