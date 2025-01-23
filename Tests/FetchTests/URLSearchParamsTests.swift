import Foundation
import Testing

@testable import Fetch

@Suite
struct URLSearchParamsTests {
  @Test func urlSearchParams() async throws {
    #expect(URLSearchParams("key1=value1&key2=value2").description == "key1=value1&key2=value2")
    #expect(URLSearchParams("https://example.com?foo=1&bar=2").description == "foo=1&bar=2")

    let url = URL(string: "https://example.com?foo=1&bar=2")!
    var params = URLSearchParams(url)
    #expect(params.description == "foo=1&bar=2")

    params.append("foo", "4")
    #expect(params.description == "foo=1&bar=2&foo=4")

    params.sort()
    #expect(params.description == "bar=2&foo=1&foo=4")
  }

  @Test func urlSearchParamsEdgeCases() async throws {
    // Test empty initialization
    let emptyParams = URLSearchParams()
    #expect(emptyParams.description == "")

    // Test URL with empty query
    let emptyQueryParams = URLSearchParams("https://example.com?")
    #expect(emptyQueryParams.description == "")

    // Test URL with invalid encoding
    let encodedParams = URLSearchParams("key%20with%20spaces=value%20with%20spaces")
    #expect(encodedParams.description == "key with spaces=value with spaces")

    // Test multiple values with same key
    var multiParams = URLSearchParams()
    multiParams.append("key", "value1")
    multiParams.append("key", "value2")
    #expect(multiParams.getAll("key") == ["value1", "value2"])

    // Test special characters
    var specialParams = URLSearchParams()
    specialParams.append("special!@#$", "value!@#$")
    let encoded = specialParams.description
    #expect(encoded.contains("%"))  // Should be URL encoded

    // Test delete with specific value
    var deleteParams = URLSearchParams()
    deleteParams.append("key", "value1")
    deleteParams.append("key", "value2")
    deleteParams.delete("key", "value1")
    #expect(deleteParams.getAll("key") == ["value2"])

    // Test keys() with duplicate keys
    var keyParams = URLSearchParams()
    keyParams.append("key1", "value1")
    keyParams.append("key1", "value2")
    keyParams.append("key2", "value3")
    let keys = keyParams.keys()
    #expect(keys.count == 2)
    #expect(keys.contains("key1"))
    #expect(keys.contains("key2"))

    // Test values() ordering
    var valueParams = URLSearchParams()
    valueParams.append("key1", "value1")
    valueParams.append("key2", "value2")
    valueParams.append("key1", "value3")
    let values = valueParams.values()
    #expect(values == ["value1", "value2", "value3"])

    // Test handling of empty values
    var nilParams = URLSearchParams()
    nilParams.append("key", "")
    #expect(nilParams.description == "key=")
  }

  @Test func urlSearchParamsEncoding() async throws {
    // Test URL encoding of special characters
    var params = URLSearchParams()
    params.append("name", "John Doe")
    params.append("email", "john+doe@example.com")
    params.append("query", "status=active&type=user")

    let encoded = params.description
    #expect(encoded.contains("%20"))  // Space should be encoded
    #expect(encoded.contains("%2B"))  // + should be encoded
    #expect(encoded.contains("%3D"))  // = should be encoded
    #expect(encoded.contains("%26"))  // & should be encoded

    // Test decoding back
    let decoded = URLSearchParams(encoded)
    #expect(decoded.get("name") == "John Doe")
    #expect(decoded.get("email") == "john+doe@example.com")
    #expect(decoded.get("query") == "status=active&type=user")
  }

  @Test func urlSearchParamsSorting() async throws {
    var params = URLSearchParams()
    params.append("c", "3")
    params.append("a", "1")
    params.append("b", "2")
    params.append("a", "4")

    params.sort()
    let sorted = params.description

    // Should be sorted by key, preserving multiple values for same key
    #expect(sorted == "a=1&a=4&b=2&c=3")
  }
}
