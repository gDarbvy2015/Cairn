//
//  HTTPClientMockTests.swift
//  Fetch
//
//  Created by Guilherme Souza on 13/01/25.
//

import Foundation
import HTTP
import HTTPMock
import Testing

@Suite
struct HTTPClientMockTests {
  @Test func basics() async throws {
    let fetch = await HTTPClientMock()
      .register(path: .substring("anything")) {
        Response(
          url: $0.url,
          body: try .json(["key": "value"]),
          headers: [
            "Content-Type": "text/plain"
          ],
          status: 200
        )
      }

    let response = try await fetch.send("https://httpbin.org/anything")
    #expect(response.status == 200)
    #expect(response.headers["Content-Type"] == "text/plain")
    #expect(try await response.json() as? [String: String] == ["key": "value"])
  }
}
