//
//  ViewController.swift
//  rs-webview
//
//  Created by Erik Jakobsson on 2024-03-12.
//

import UIKit
import WebKit

// Define where in the DOM to look for the Vindral instance
// On the view, call `self.eventHandler.attachHooks` when the instance has been established.
// In this example, this is done in the WKWebView didFinish navigation delegate call.
let instanceQuery: String = "window.vindral"

class ViewController: UIViewController {
  let eventHandler = VindralEventHandler(instance: instanceQuery)
  lazy var bridge = VindralBridge(instance: instanceQuery, view: self.webView)
  
  lazy var webView: WKWebView = {
    let config = WKWebViewConfiguration()
    
    let eventHandler = self.eventHandler
    eventHandler.delegate = self
    config.userContentController = eventHandler
    
    let view = WKWebView(frame: .zero, configuration: config)
        
    if #available(iOS 16.4, *) {
      view.isInspectable = true
    }
    view.navigationDelegate = self
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  override func viewDidLoad() {
    self.view.addSubview(self.webView)

    NSLayoutConstraint.activate([
      self.webView.topAnchor.constraint(equalTo: self.view.topAnchor),
      self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
      self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
      self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
    ])

    let url = URL(string: "https://qos.vindral.com/?core.url=https://lb.cdn.vindral.com&core.channelId=vindral_demo1_ci_099ee1fa-80f3-455e-aa23-3d184e93e04f")!
    
    let request = URLRequest(url: url)
    self.webView.load(request)
  }
}

extension ViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let credential = URLCredential(
      user: "AzureDiamond",
      password: "hunter2",
      persistence: .forSession)
    completionHandler(.useCredential, credential)
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    print("Navigated to: \(String(describing: self.webView.url))")
    
    
    self.eventHandler.attachHooks(view: self.webView) { res in
      switch res {
        case .failure(let error):
          print("Error attaching event handler: \(error)")
          return

        case .success(_):
          print("Attached event handlers")
          
          if #available(iOS 14.0, *) {
            self.bridge.play { res in
              switch res {
                case .success(_):
                  print("Play success")
                  break
                case .failure(let error):
                  print("Play failed: \(error)")
                  break
              }
            }
          }
      }
    }
  }
}

extension ViewController: VindralEventHandlerDelegate {
  func channels(channels: Array<VindralJsChannel>) {
    print("Delegate got channels: \(channels)")
  }
  
  func channelSwitch(channel: String) {
    print("Delegate got channelSwitch: \(channel)")
  }
  
  func connectionState(state: VindralConnectionState) {
    print("Delegate got connectionState: \(state)")
  }
  
  func contextSwitch(state: VindralContextSwitchState) {
    print("Delegate got contextSwitch: \(state)")
  }
  
  func error(error: VindralError) {
    print("Delegate got error: \(error)")
  }
  
  func languages(languages: Array<String>) {
    print("Delegate got languages: \(languages)")
  }
  
  func languageSwitch(langugage: String) {
    print("Delegate got languageSwitch: \(langugage)")
  }
  
  func live(live: Bool) {
    print("Delegate got live: \(live)")
  }
  
  func metadata(metadata: VindralTimedMetadata) {
    print("Delegate got metadata: \(metadata)")
  }
  
  func needsUserInput(context: VindralNeedsUserInputContext) {
    print("Delegate got needsUserInput: \(context)")
  }
  
  func playbackState(state: VindralPlaybackState) {
    print("Delegate got playbackState: \(state)")
    
    switch state {
      case .playing:
        self.bridge.getThumbnailUrl { res in
          switch res {
            case .success(let url):
              print("Got thumbnail url: \(url)")
              break
            case .failure(let error):
              print("Error getting thumbnail url: \(error)")
              break
          }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
          self.bridge.getStatistics { res in
            switch res {
              case .success(let stats):
                print("Got stats: \(stats)")
                break
              case .failure(let error):
                print("Error getting stats: \(error)")
                break
            }
          }
        }
        break
      default:
        break
    }
  }
  
  func renditionLevel(level: VindralRenditionLevel) {
    print("Delegate got renditionLevel: \(level)")
  }
  
  func renditionLevels(levels: Array<VindralRenditionLevel>) {
    print("Delegate got renditionLevels: \(levels)")
  }
  
  func serverWallClockTime(time: Int64) {
    print("Delegate got serverWallClockTime: \(time)")
  }
  
  func volumeState(state: VindralVolumeState) {
    print("Delegate got volumeState: \(state)")
  }
}
