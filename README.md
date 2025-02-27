# HTTP
[![codecov](https://codecov.io/gh/grdsdev/swift-http/graph/badge.svg?token=E4i22yGg9o)](https://codecov.io/gh/grdsdev/swift-http)

The `HTTP` package provides a Swift interface for making HTTP requests and
processing responses. It is designed to be simple and intuitive, allowing developers to easily integrate HTTP functionality into their Swift applications.

## Features

- Simple and intuitive API for making HTTP requests
- Support for various HTTP methods (GET, POST, PUT, DELETE, etc.)
- Flexible request options, including custom headers and body
- Asynchronous operations using Swift's async/await
- Built-in support for JSON encoding and decoding
- Multipart form data support
- URL search parameters handling
- Support for streamed responses

## Installation

To integrate the `HTTP` package into your Swift project, add the following line to your `Package.swift` file:

```swift
.package(url: "https://github.com/grdsdev/swift-http.git", from: "0.0.1")
```

Then, include "HTTP" in your target dependencies:

```swift
.target(
  name: "YourTargetName", 
  dependencies: [
    .product(name: "HTTP", package: "swift-http"), 
    .product(name: "HTTPFoundation", package: "swift-http"),
  ]
)
```

## Usage

### Basic GET Request

```swift
import HTTP
import HTTPFoundation

let response = try await http.get("https://api.example.com/data")
let json = try await response.json()
```

### POST Request with JSON Body

```swift
import HTTP
import HTTPFoundation

let response = try await http.post(
  "https://api.example.com/users", 
  body: ["name": "John Doe", "age": 30]
)
```

### Multipart Form Data

```swift
import HTTP
import HTTPFoundation

var formData = FormData()
formData.append("username", "johndoe")
formData.append("avatar", imageData, filename: "avatar.jpg", contentType: "image/jpeg")

let response = try await http.post(
  "https://api.example.com/upload", 
  body: formData
)
```

### URL Search Parameters

```swift
import HTTP

var params = URLSearchParams("https://example.com?foo=1&bar=2")
params.append("baz", "3")
print(params.description) // Output: foo=1&bar=2&baz=3
```

### Streamed Responses

```swift
import HTTP
import HTTPFoundation

let response = try await http.get("https://api.example.com/stream")

for await chunk in response.body {
  // handle chunk of Data
}
```

# API Reference

For detailed API documentation, please refer to the inline comments in the
source code.

## Requirements

- Swift 5.9+
- macOS 10.15+ or iOS 13.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
