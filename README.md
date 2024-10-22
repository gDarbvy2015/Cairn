# Fetch API

The `Fetch` package provides a Swift interface for making HTTP requests and
processing responses, inspired by the
[Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) commonly
used in web development.

## Features

- Simple and intuitive API for making HTTP requests
- Support for various HTTP methods (GET, POST, PUT, DELETE, etc.)
- Flexible request options, including custom headers and body
- Asynchronous operations using Swift's async/await
- Built-in support for JSON encoding and decoding
- Multipart form data support
- URL search parameters handling

## Installation

Add the following line to your `Package.swift` file:

```swift
.package(url: "https://github.com/grdsdev/swift-fetch.git", from: "0.0.1")
```

Then, add "Fetch" to your target dependencies.

## Usage

### Basic GET Request

```swift
import Fetch

let response = try await fetch("https://api.example.com/data")
let data: SomeDecodableType = try await response.json()
```

### POST Request with JSON Body

```swift
import Fetch

let response = try await fetch(
  "https://api.example.com/users", 
  options: RequestOptions(
    method: "POST",
    body: ["name": "John Doe", "age": 30],
    headers: ["Content-Type": "application/json"]
  )
)
```

### Multipart Form Data

```swift
import Fetch

var formData = FormData()
formData.append("username", "johndoe")
formData.append("avatar", imageData, filename: "avatar.jpg", contentType: "image/jpeg")

let response = try await fetch(
  "https://api.example.com/upload", 
  options: RequestOptions(
    method: "POST", 
    body: formData
  )
)
```

### URL Search Parameters

```swift
import Fetch
var params = URLSearchParams("https://example.com?foo=1&bar=2")
params.append("baz", "3")
print(params.description) // Output: foo=1&bar=2&baz=3
```

# API Reference

For detailed API documentation, please refer to the inline comments in the
source code.

## Requirements

- Swift 6.0+
- macOS 12.0+ or iOS 13.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
