import Foundation
import Testing

@testable import Fetch

@Test func decodeStringResponse() async throws {
  let stringResponse = Response(
    url: URL(string: "https://api.example.com/data")!, body: "string value".data(using: .utf8)!,
    headers: [:], status: 200)

  #expect(await stringResponse.text() == "string value")
  try #expect(await stringResponse.json() as String == "string value")
  try #expect(await stringResponse.json() as Data == Data("string value".utf8))

}

@Test func decodeJSONResponse() async throws {
  struct JSON: Decodable {
    let value: String
  }

  let response = Response(
    url: URL(string: "https://api.example.com/data")!,
    body: #"{ "value": "string value" }"#.data(using: .utf8)!,
    headers: [:],
    status: 200
  )

  let json = try await response.json() as JSON
  #expect(json.value == "string value")
}
