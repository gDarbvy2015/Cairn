import Foundation
import Testing

@testable import Fetch

@Test func urlSearchParams() async throws {
  #expect(URLSearchParams("key1=value1&key2=value2").description == "key1=value1&key2=value2")
  #expect(URLSearchParams("https://example.com?foo=1&bar=2").description == "foo=1&bar=2")

  let url = URL(string: "https://example.com?foo=1&bar=2")!
  var params = URLSearchParams(url)
  #expect(params.description == "foo=1&bar=2")

  params.append("foo", 4)
  #expect(params.description == "foo=1&bar=2&foo=4")

  params.sort()
  #expect(params.description == "bar=2&foo=1&foo=4")
}
