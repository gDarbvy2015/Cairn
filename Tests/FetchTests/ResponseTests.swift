import Foundation
import Testing

@testable import HTTP

@Test func textResponse() async throws {
  let stringResponse = Response(
    url: URL(string: "https://api.example.com/data")!,
    body: .string("string value"),
    headers: [:],
    status: 200
  )

  #expect(await stringResponse.text() == "string value")
}

@Test func decodeStringResponse() async throws {
  let stringResponse = Response(
    url: URL(string: "https://api.example.com/data")!,
    body: .string("string value"),
    headers: [:],
    status: 200
  )

  try #expect(await stringResponse.decode() as String == "string value")
}

@Test func decodeDataResponse() async throws {
  let stringResponse = Response(
    url: URL(string: "https://api.example.com/data")!,
    body: .string("string value"),
    headers: [:],
    status: 200
  )

  try #expect(await stringResponse.decode() as Data == Data("string value".utf8))
}

@Test func decodeJSONResponse() async throws {
  struct JSON: Decodable {
    let value: String
  }

  let response = Response(
    url: URL(string: "https://api.example.com/data")!,
    body: .string(#"{ "value": "string value" }"#),
    headers: [:],
    status: 200
  )

  let json = try await response.decode() as JSON
  #expect(json.value == "string value")
}
