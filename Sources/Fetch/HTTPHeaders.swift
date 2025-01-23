/// A case-insensitive collection of HTTP headers
public struct HTTPHeaders: Sendable, Hashable {
  private var headers: [String: String] = [:]

  public init() {}

  public init(_ headers: [String: String]) {
    headers.forEach { self[normalize($0.key)] = $0.value }
  }

  public var dictionary: [String: String] {
    headers
  }
}

// MARK: - Subscript Access
extension HTTPHeaders {
  public subscript(_ key: String) -> String? {
    get {
      headers[normalize(key)]
    }
    set {
      let normalizedKey = normalize(key)
      if let newValue = newValue {
        headers[normalizedKey] = newValue
      } else {
        headers.removeValue(forKey: normalizedKey)
      }
    }
  }

  private func normalize(_ name: String) -> String {
    name.lowercased()
  }
}

// MARK: - Collection Conformance
extension HTTPHeaders: Collection {
  public var startIndex: Dictionary<String, String>.Index {
    headers.startIndex
  }

  public var endIndex: Dictionary<String, String>.Index {
    headers.endIndex
  }

  public func index(after i: Dictionary<String, String>.Index) -> Dictionary<String, String>.Index {
    headers.index(after: i)
  }

  public subscript(position: Dictionary<String, String>.Index)
    -> Dictionary<String, String>.Element
  {
    headers[position]
  }
}

// MARK: - ExpressibleByDictionaryLiteral
extension HTTPHeaders: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, String)...) {
    self.init()
    elements.forEach { self[$0.0] = $0.1 }
  }
}
