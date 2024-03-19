//
//  VindralEventHandler.swift
//  rs-webview
//
//  Created by Erik Jakobsson on 2024-03-12.
//

import WebKit

class VindralEventHandler: WKUserContentController {
  weak var delegate: VindralEventHandlerDelegate?
  
  private static let attachFunction = "attachVindralHandlers"
  private static let detachFunction = "detachVindralHandlers"
  
  init(instance: String, delegate: VindralEventHandlerDelegate? = nil) {
    super.init()
    self.delegate = delegate
    
    var attachFunction = "function \(VindralEventHandler.attachFunction)() {\n"
    var detachFunction = "function \(VindralEventHandler.detachFunction)() {\n"
    var functions = "var vindralEventHandlers = {\n"
    
    for event in VindralEvent.allCases {
      attachFunction += "\t\(event.onCode(query: instance))\n"
      detachFunction += "\t\(event.offCode(query: instance))\n"
      functions += "\t\(event.functionCode(query: instance)),\n"
      self.add(self, name: event.handler())
    }
    
    attachFunction += "}\n"
    detachFunction += "}\n"
    functions += "}\n"
    
    print(functions)
    print(attachFunction)
    
    let functionsScript = WKUserScript(source: functions, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    self.addUserScript(functionsScript)
    let attachScript = WKUserScript(source: attachFunction, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    self.addUserScript(attachScript)
    let detachScript = WKUserScript(source: detachFunction, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    self.addUserScript(detachScript)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func attachHooks(view: WKWebView, onComplete: @escaping (Result<Any, any Error>) -> Void) {
    if #available(iOS 14.0, *) {
      // Wait for instance to exists if it's loaded async
      let code = """
        let loops = 0
        while (!\(instanceQuery)) {
          if (loops > 20) {
            throw new Error("Could not find \(instanceQuery)");
          }
          await new Promise(r => setTimeout(r, 100))
          loops++
        }
"""
      view.callAsyncJavaScript(code, in: .none, in: .page) { res in
        switch res {
          case .failure(let error):
            onComplete(.failure(error))
            return
          case .success(_):
            view.evaluateJavaScript("\(VindralEventHandler.attachFunction)()") { res, error in
              if let error = error {
                onComplete(.failure(error))
                return
              }
              onComplete(.success(()))
            }
        }
      }
    } else {
      view.evaluateJavaScript("\(VindralEventHandler.attachFunction)()") { res, error in
        if let error = error {
          onComplete(.failure(error))
          return
        }
        onComplete(.success(()))
      }
    }
  }
  
  func detachHooks(view: WKWebView, onComplete: @escaping (Result<(),Error>) -> Void) {
    view.evaluateJavaScript("\(VindralEventHandler.detachFunction)()") { res, error in
      if let error = error {
        onComplete(.failure(error))
        return
      }
      onComplete(.success(()))
    }
  }
}


extension VindralEventHandler: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

    do {
      switch message.name {
        case VindralEvent.channels.handler():
          let data = try JSONSerialization.data(withJSONObject: message.body)
          let channels = try JSONDecoder().decode(Array<VindralJsChannel>.self, from: data)
          self.delegate?.channels(channels: channels)
          break
        case VindralEvent.channelSwitch.handler():
          let data = try JSONSerialization.data(withJSONObject: message.body)
          let channel = try JSONDecoder().decode(VindralChannelSwitch.self, from: data)
          self.delegate?.channelSwitch(channel: channel.channelId)
          break
        case VindralEvent.connectionState.handler():
          let state = VindralConnectionState(rawValue: message.body as! String)!
          self.delegate?.connectionState(state: state)
          break
        case VindralEvent.contextSwitch.handler():
          let state = VindralContextSwitchState(rawValue: message.body as! String)!
          self.delegate?.contextSwitch(state: state)
          break
        case VindralEvent.error.handler():
          guard let dict = message.body as? [String: Any?] else {
            print("Could not parse error: \(message.body)")
            return
          }
          guard let code = dict["code"] as? String, let isFatal = dict["isFatal"] as? Bool, let message = dict["message"] as? String else {
            print("Could not parse error: \(dict)")
            return
          }
          self.delegate?.error(error: VindralError(code: code, message: message, isFatal: isFatal))
          break
        case VindralEvent.languages.handler():
          guard let languages = message.body as? Array<String> else {
            print("Could not parse languages")
            return
          }
          self.delegate?.languages(languages: languages)
          break
        case VindralEvent.languageSwitch.handler():
          guard let language = message.body as? String else {
            print("Could not parse language")
            return
          }
          self.delegate?.languageSwitch(langugage: language)
          break
        case VindralEvent.live.handler():
          guard let state = message.body as? Bool else {
            print("Could not parse live state")
            return
          }
          self.delegate?.live(live: state)
          break
        case VindralEvent.metadata.handler():
          let data = try JSONSerialization.data(withJSONObject: message.body)
          let metadata = try JSONDecoder().decode(VindralTimedMetadata.self, from: data)
          self.delegate?.metadata(metadata: metadata)
          break
        case VindralEvent.needsUserInput.handler():
          let data = try JSONSerialization.data(withJSONObject: message.body)
          let context = try JSONDecoder().decode(VindralNeedsUserInputContext.self, from: data)
          self.delegate?.needsUserInput(context: context)
          break
        case VindralEvent.playbackState.handler():
          let state = VindralPlaybackState(rawValue: message.body as! String)!
          self.delegate?.playbackState(state: state)
          break
        case VindralEvent.renditionLevel.handler():
          let data = try JSONSerialization.data(withJSONObject: message.body)
          let level = try JSONDecoder().decode(VindralRenditionLevel.self, from: data)
          self.delegate?.renditionLevel(level: level)
          break
        case VindralEvent.renditionLevels.handler():
          let data = try JSONSerialization.data(withJSONObject: message.body)
          let levels = try JSONDecoder().decode(Array<VindralRenditionLevel>.self, from: data)
          self.delegate?.renditionLevels(levels: levels)
          break
        case VindralEvent.serverWallclockTime.handler():
          guard let time = message.body as? Int64 else {
            print("Could not parse serverWallclockTime")
            return
          }
          self.delegate?.serverWallClockTime(time: time)
          break
        case VindralEvent.volumeState.handler():
          let data = try JSONSerialization.data(withJSONObject: message.body)
          let state = try JSONDecoder().decode(VindralVolumeState.self, from: data)
          self.delegate?.volumeState(state: state)
          break
        default:
          print("Unknown event: \(message.name): \(message.body)")
          break
      }
    } catch {
      print("Error handling \(message.name): \(message.body): \(error)")
    }
  }
}
