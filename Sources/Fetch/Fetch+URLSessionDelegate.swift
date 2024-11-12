////
////  Fetch+URLSessionDelegate.swift
////  Fetch
////
////  Created by Guilherme Souza on 01/11/24.
////
//
//import Foundation
//
//final class DataDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
//  private let handlers = TaskHandlersDictionary()
//
//  var userSessionDelegate: URLSessionDelegate? {
//    didSet {
//      userTaskDelegate = userSessionDelegate as? URLSessionTaskDelegate
//      userDataDelegate = userSessionDelegate as? URLSessionDataDelegate
//      userDownloadDelegate = userSessionDelegate as? URLSessionDownloadDelegate
//    }
//  }
//
//  var userTaskDelegate: URLSessionTaskDelegate?
//  var userDataDelegate: URLSessionDataDelegate?
//  var userDownloadDelegate: URLSessionDownloadDelegate?
//
//  func startDataTask(
//    _ task: URLSessionDataTask, session: URLSession, delegate: URLSessionDataDelegate?
//  ) async throws -> Response {
//    try await withTaskCancellationHandler {
//      try await withUnsafeThrowingContinuation { continuation in
//        let handler = DataTaskHandler(delegate: delegate)
//        handler.completion = { continuation.resume(with: $0) }
//        self.handlers[task] = handler
//        task.resume()
//      }
//    } onCancel: {
//      task.cancel()
//    }
//  }
//
//  func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
//    userSessionDelegate?.urlSession?(session, didBecomeInvalidWithError: error)
//  }
//
//  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//    userSessionDelegate?.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
//  }
//
//  func urlSession(
//    _ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?
//  ) {
//    guard let handler = handlers[task] else {
//      assertionFailure()
//      return
//    }
//    handlers[task] = nil
//
//    handler.delegate?.urlSession?(session, task: task, didCompleteWithError: error)
//    userTaskDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
//
//    switch handler {
//    case let handler as DataTaskHandler:
//      if let response = task.response as? HTTPURLResponse, error == nil {
//        let data = handler.data ?? Data()
//        let response = Response(
//          url: response.url!,
//          body: data,
//          headers: response.allHeaderFields as? [String: String] ?? [:],
//          status: response.statusCode
//        )
//        handler.completion?(.success(response))
//      } else {
//        handler.completion?(.failure(error ?? URLError(.unknown)))
//      }
//    default:
//      break
//    }
//  }
//
//  func urlSession(
//    _ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics
//  ) {
//    let handler = handlers[task]
//
//    handler?.delegate?.urlSession?(session, task: task, didFinishCollecting: metrics)
//    userTaskDelegate?.urlSession?(session, task: task, didFinishCollecting: metrics)
//  }
//
//  func urlSession(
//    _ session: URLSession, task: URLSessionTask,
//    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest
//  ) async -> URLRequest? {
//    if let request = await handlers[task]?.delegate?.urlSession?(
//      session, task: task, willPerformHTTPRedirection: response, newRequest: request)
//    {
//      return request
//    } else if let request = await userTaskDelegate?.urlSession?(
//      session, task: task, willPerformHTTPRedirection: response, newRequest: request)
//    {
//      return request
//    } else {
//      return request
//    }
//  }
//
//  func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
//    handlers[task]?.delegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
//    userTaskDelegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
//  }
//
//  func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
//    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
//      handlers[task]?.delegate?.urlSession?(session, didCreateTask: task)
//      userTaskDelegate?.urlSession?(session, didCreateTask: task)
//    } else {
//      // Fallback on earlier versions
//    }
//  }
//
//  func urlSession(
//    _ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge
//  ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
//    if let result = await handlers[task]?.delegate?.urlSession?(
//      session, task: task, didReceive: challenge)
//    {
//      return result
//    } else if let result = await userTaskDelegate?.urlSession?(
//      session, task: task, didReceive: challenge)
//    {
//      return result
//    } else {
//      return (.performDefaultHandling, nil)
//    }
//  }
//
//  func urlSession(
//    _ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest,
//    completionHandler: @Sendable @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void
//  ) {
//    handlers[task]?.delegate?.urlSession?(
//      session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler)
//      ?? userTaskDelegate?.urlSession?(
//        session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler)
//      ?? completionHandler(.continueLoading, nil)
//  }
//
//  func urlSession(
//    _ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64,
//    totalBytesSent: Int64, totalBytesExpectedToSend: Int64
//  ) {
//
//    handlers[task]?.delegate?.urlSession?(
//      session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent,
//      totalBytesExpectedToSend: totalBytesExpectedToSend)
//      ?? userTaskDelegate?.urlSession?(
//        session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent,
//        totalBytesExpectedToSend: totalBytesExpectedToSend)
//  }
//}
//
//private class TaskHandler {
//  let delegate: URLSessionTaskDelegate?
//  init(delegate: URLSessionTaskDelegate?) {
//    self.delegate = delegate
//  }
//}
//
//private final class DataTaskHandler: TaskHandler {
//  typealias Completion = (Result<Response, any Error>) -> Void
//
//  let dataDelegate: URLSessionDataDelegate?
//  var completion: Completion?
//  var data: Data?
//
//  override init(delegate: (any URLSessionTaskDelegate)?) {
//    self.dataDelegate = delegate as? URLSessionDataDelegate
//    super.init(delegate: delegate)
//  }
//}
//
//private final class TaskHandlersDictionary: @unchecked Sendable {
//  let lock = NSLock()
//  var handlers: [URLSessionTask: TaskHandler] = [:]
//
//  subscript(task: URLSessionTask) -> TaskHandler? {
//    get {
//      lock.withLock { handlers[task] }
//    }
//    set {
//      lock.withLock { handlers[task] = newValue }
//    }
//  }
//}
