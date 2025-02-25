import Testing

@testable import HTTP

@Suite struct HTTPHeadersTests {
  @Test func initEmpty() {
    let headers = HTTPHeaders()
    #expect(headers.startIndex == headers.endIndex)
  }

  @Test func initWithDictionary() {
    let headers = HTTPHeaders([
      "Content-Type": "application/json",
      "Accept": "text/html",
    ])

    #expect(headers["Content-Type"] == "application/json")
    #expect(headers["Accept"] == "text/html")
  }

  @Test func caseInsensitiveAccess() {
    var headers = HTTPHeaders()
    headers["Content-Type"] = "application/json"

    #expect(headers["content-type"] == "application/json")
    #expect(headers["CONTENT-TYPE"] == "application/json")
    #expect(headers["Content-Type"] == "application/json")
  }

  @Test func updateExistingHeader() {
    var headers = HTTPHeaders()
    headers["Content-Type"] = "application/json"
    headers["CONTENT-TYPE"] = "text/plain"

    #expect(headers["Content-Type"] == "text/plain")
  }

  @Test func removeHeader() {
    var headers = HTTPHeaders()
    headers["Content-Type"] = "application/json"
    headers["Content-Type"] = nil

    #expect(headers["Content-Type"] == nil)
  }

  @Test func dictionaryLiteralInitialization() {
    let headers: HTTPHeaders = [
      "Content-Type": "application/json",
      "Accept": "text/html",
    ]

    #expect(headers["Content-Type"] == "application/json")
    #expect(headers["Accept"] == "text/html")
  }

  @Test func collectionConformance() {
    let headers: HTTPHeaders = [
      "Content-Type": "application/json",
      "Accept": "text/html",
    ]

    let headerPairs = Array(headers)
    #expect(headerPairs.count == 2)
    #expect(
      headerPairs.contains(where: { $0.key == "content-type" && $0.value == "application/json" }))
    #expect(headerPairs.contains(where: { $0.key == "accept" && $0.value == "text/html" }))
  }

  @Test func hashableConformance() {
    let headers1: HTTPHeaders = ["Content-Type": "application/json"]
    let headers2: HTTPHeaders = ["content-type": "application/json"]
    let headers3: HTTPHeaders = ["Content-Type": "text/plain"]

    #expect(headers1 == headers2)
    #expect(headers1 != headers3)

    var headerSet = Set<HTTPHeaders>()
    headerSet.insert(headers1)
    headerSet.insert(headers2)

    #expect(headerSet.count == 1)
  }
}
