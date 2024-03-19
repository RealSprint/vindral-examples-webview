//
//  Event.swift
//  rs-webview
//
//  Created by Erik Jakobsson on 2024-03-12.
//

internal enum VindralEvent: String, CaseIterable {
  case channels = "channels"
  case channelSwitch = "channel switch"
  case connectionState = "connection state"
  case contextSwitch = "context switch"
  case error = "error"
  case languages = "languages"
  case languageSwitch = "language switch"
  case live = "is live"
  case metadata = "metadata"
  case needsUserInput = "needs user input"
  case playbackState = "playback state"
  case renditionLevel = "rendition level"
  case renditionLevels = "rendition levels"
  case serverWallclockTime = "server wallclock time"
  case volumeState = "volume state"

  func handler() -> String {
    String(describing: self)
  }
  
  func functionCode(query: String) -> String {
    switch self {
      case .error:
        return "\(self.handler())Handler: (e) => { window.webkit.messageHandlers.\(self.handler()).postMessage({ code: e.code(), message: e.message, isFatal: e.isFatal() }) }"
      default:
        return "\(self.handler())Handler: (action) => { window.webkit.messageHandlers.\(self.handler()).postMessage(action) }"
    }
    
  }
  
  func onCode(query: String) -> String {
    return "\(query).on(\"\(self.rawValue)\", vindralEventHandlers.\(self.handler())Handler)"
  }
  
  func offCode(query: String) -> String {
    return "\(query).off(\"\(self.rawValue)\", vindralEventHandlers.\(self.handler())Handler)"
  }
}
