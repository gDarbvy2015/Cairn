//
//  FetchTests.swift
//  Fetch
//
//  Created by Guilherme Souza on 12/12/24.
//

import Foundation
import HTTPFoundation
import Testing

@Suite
struct FetchTests {
  @Test func requestWithData() async throws {
    struct ExpectedPayload: Decodable {
      var method: String
      let data: String
      let headers: [String: String]
    }

    let response = try await http.post(
      "https://httpbin.org/anything",
      body: .data(Data("Hello World".utf8)),
      headers: ["Content-Type": "text/plain"]
    )

    let payload = try await response.decode(as: ExpectedPayload.self)

    #expect(payload.method == "POST")
    #expect(payload.data == "Hello World")
    #expect(payload.headers["Content-Type"] == "text/plain")
  }

  @Test func requestWithString() async throws {
    struct ExpectedPayload: Decodable {
      var method: String
      let data: String
      let headers: [String: String]
    }

    let body = "Hello World"

    let response = try await http.post(
      "https://httpbin.org/anything",
      body: .string(body),
      headers: ["Content-Type": "application/octet-stream"]
    )

    let payload = try await response.decode(as: ExpectedPayload.self)

    #expect(payload.data == body)
  }

  @Test func requestWithFormData() async throws {
    struct ExpectedPayload: Decodable {
      var method: String
      let form: [String: String]
      let headers: [String: String]
    }

    var body = FormData()
    try body.append("file", .string("Hello World"))

    let response = try await http.post(
      "https://httpbin.org/anything",
      body: .formData(body),
      headers: ["Content-Type": body.contentType]
    )

    let payload = try await response.decode(as: ExpectedPayload.self)

    #expect(payload.form == ["file": "Hello World"])
  }

  @Test func requestWithURLSearchParams() async throws {
    struct ExpectedPayload: Decodable {
      var method: String
      let form: [String: String]
      let headers: [String: String]
    }

    var body = URLSearchParams()
    body.append("username", "admin")
    body.append("password", "pass123")

    let response = try await http.post(
      "https://httpbin.org/anything",
      body: .urlSearchParams(body),
      headers: ["Content-Type": "application/x-www-form-urlencoded"]
    )

    let payload = try await response.decode(as: ExpectedPayload.self)

    #expect(payload.form == ["username": "admin", "password": "pass123"])
  }

  @Test func requestWithJSONObject() async throws {
    struct ResponsePayload: Decodable, Equatable {
      let username: String
      let password: String
      let age: Int
    }
    struct ExpectedPayload: Decodable {
      var method: String
      let json: ResponsePayload
      let headers: [String: String]
    }

    let body =
      [
        "username": "admin",
        "password": "pass123",
        "age": 18,
      ] as [String: any Sendable]

    let response = try await http.post(
      "https://httpbin.org/anything",
      body: .json(body),
      headers: ["Content-Type": "application/json"]
    )

    let payload = try await response.decode(as: ExpectedPayload.self)

    #expect(
      payload.json
        == ResponsePayload(
          username: "admin",
          password: "pass123",
          age: 18
        )
    )
  }

  @Test func requestWithEncodable() async throws {
    struct Credential: Codable, Equatable {
      let username: String
      let password: String
    }
    struct ExpectedPayload: Decodable {
      var method: String
      let json: Credential
      let headers: [String: String]
    }

    let body = Credential(
      username: "admin",
      password: "pass123"
    )

    let response = try await http.post(
      "https://httpbin.org/anything",
      body: .encodable(body),
      headers: ["Content-Type": "application/json"]
    )

    let payload = try await response.decode(as: ExpectedPayload.self)

    #expect(payload.json == body)
  }

  @Test func streamResponse() async throws {
    let response = try await http.get("https://httpbin.org/stream-bytes/10")

    var result = ""
    for await chunk in response.body {
      result.append(
        chunk.compactMap {
          String(format: "%02x", $0)
        }.joined())
    }
    #expect(result.count == 20)
  }

}
