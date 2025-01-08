//
//  FetchTests.swift
//  Fetch
//
//  Created by Guilherme Souza on 12/12/24.
//

import Foundation
import Testing

@testable import Fetch

@Test func basics() async throws {
  struct ExpectedPayload: Decodable {
    var method: String
    let data: String
    let headers: [String: String]
  }

  let response = try await fetch(
    "https://httpbin.org/anything",
    options: RequestOptions(
      method: "POST",
      body: Data("Hello World".utf8),
      headers: ["Content-Type": "text/plain"]
    )
  )

  let payload = try await response.decode(as: ExpectedPayload.self)

  #expect(payload.method == "POST")
  #expect(payload.data == "Hello World")
  #expect(payload.headers["Content-Type"] == "text/plain")
}

@Test func streamResponse() async throws {
  let response = try await fetch("https://httpbin.org/stream-bytes/10")

  var result = ""
  for await chunk in response.body {
    result.append(
      chunk.compactMap {
        String(format: "%02x", $0)
      }.joined())
  }
  #expect(result.count == 20)
}
