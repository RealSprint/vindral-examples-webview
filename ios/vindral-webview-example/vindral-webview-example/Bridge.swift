//
//  Bridge.swift
//  rs-webview
//
//  Created by Erik Jakobsson on 2024-03-12.
//

import WebKit

enum VindralBridgeError: Error {
  case conversionError(String)
}

class VindralBridge {
  var instance: String
  weak var view: WKWebView?
  
  init(instance: String, view: WKWebView) {
    self.instance = instance
    self.view = view;
  }
  
  @available(iOS 14.0, *)
  private func callAsync(function: String, onComplete: @escaping (Result<Any, any Error>) -> Void) {
    guard let view = self.view else {
      return
    }
    
    view.callAsyncJavaScript(function, in: .none, in: .page, completionHandler: onComplete)
  }
    
  private func call(code: String, onComplete: @escaping (Result<(),Error>) -> Void) {
    guard let view = self.view else {
      return
    }
    
    view.evaluateJavaScript(code) { response, error in
      if let error = error {
        onComplete(.failure(error))
        return
      }
      onComplete(.success(()))
    }
  }
  
  private func call<T>(code: String, convert: @escaping ((Any?) throws -> T), onComplete: @escaping (Result<T,Error>) -> Void) {
    guard let view = self.view else {
      return
    }
    
    view.evaluateJavaScript(code) { response, error in
      if let error = error {
        onComplete(.failure(error))
      }
      do {
        let value = try convert(response)
        onComplete(.success(value))
      } catch {
        onComplete(.failure(error))
      }
    }
  }
  
  func attach(element: String, onComplete: @escaping (Result<Void, Error>) -> Void) {
    self.call(code: "\(self.instance).attach(\(element))", onComplete: onComplete)
  }
  
  @available(iOS 14.0, *)
  func play(onComplete: @escaping (Result<Any, any Error>) -> Void) {
    self.callAsync(function: "await \(self.instance).play()", onComplete: onComplete)
  }
  
  func pause(onComplete: @escaping (Result<Void, Error>) -> Void) {
    self.call(code: "\(self.instance).pause()", onComplete: onComplete)
  }
  
  func updateAuthenticationToken(token: String, onComplete: @escaping (Result<Void, Error>) -> Void) {
    self.call(code: "\(self.instance).updateAuthenticationToken(\(token))", onComplete: onComplete)
  }
  
  @available(iOS 14.0, *)
  func unload(onComplete: @escaping (Result<Any, any Error>) -> Void) {
    self.callAsync(function: "await \(self.instance).unload()", onComplete: onComplete)
  }
  
  func getStatistics(onComplete: @escaping (Result<VindralStatistics, Error>) -> Void) {
    let code = "\(self.instance).getStatistics()"
    
    self.call(code: code, convert: { res in
      let data = try JSONSerialization.data(withJSONObject: res as Any)
      let stats = try JSONDecoder().decode(VindralStatistics.self, from: data)
      return stats
    }, onComplete: onComplete)
  }
  
  func getThumbnailUrl(onComplete: @escaping (Result<String, Error>) -> Void) {
    let code = "\(self.instance).getThumbnailUrl()"
    
    self.call(code: code, convert: { res in
      guard let value = res as? String else {
        throw VindralBridgeError.conversionError("getThumbnailUrl value not string")
      }
      return value
    }, onComplete: onComplete)
  }
}
