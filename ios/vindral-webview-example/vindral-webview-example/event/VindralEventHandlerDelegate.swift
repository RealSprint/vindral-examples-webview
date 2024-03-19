//
//  VindralEventHandlerDelegate.swift
//  rs-webview
//
//  Created by Erik Jakobsson on 2024-03-12.
//

public protocol VindralEventHandlerDelegate: AnyObject {
  func channels(channels: Array<VindralJsChannel>)
  func channelSwitch(channel: String)
  func connectionState(state: VindralConnectionState)
  func contextSwitch(state: VindralContextSwitchState)
  func error(error: VindralError)
  func languages(languages: Array<String>)
  func languageSwitch(langugage: String)
  func live(live: Bool)
  func metadata(metadata: VindralTimedMetadata)
  func needsUserInput(context: VindralNeedsUserInputContext)
  func playbackState(state: VindralPlaybackState)
  func renditionLevel(level: VindralRenditionLevel)
  func renditionLevels(levels: Array<VindralRenditionLevel>)
  func serverWallClockTime(time: Int64)
  func volumeState(state: VindralVolumeState)
}
