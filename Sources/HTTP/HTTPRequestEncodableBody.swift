//
//  HTTPRequestEncodableBody.swift
//  Fetch
//
//  Created by Guilherme Souza on 08/01/25.
//

import Foundation
import HTTPTypes

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A protocol that defines a type that can be encoded into an HTTP request body.
///
/// Types conforming to this protocol can be used as the body of an HTTP request.
/// The protocol provides a default implementation of the `encoder` property,
/// which returns a JSON encoder.
public protocol HTTPRequestEncodableBody: Encodable, Sendable {
  static var encoder: JSONEncoder { get }
}

extension HTTPRequestEncodableBody {
  public static var encoder: JSONEncoder {
    JSONEncoder.default
  }
}

extension Array: HTTPRequestEncodableBody where Element: HTTPRequestEncodableBody {
  public static var encoder: JSONEncoder { Element.encoder }
}

extension Dictionary: HTTPRequestEncodableBody
where Key == String, Value: HTTPRequestEncodableBody {
  public static var encoder: JSONEncoder { Value.encoder }
}
