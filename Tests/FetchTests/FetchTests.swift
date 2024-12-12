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
  let response = try await fetch("https://httpbin.org/get")
  #expect(response.ok)
}
