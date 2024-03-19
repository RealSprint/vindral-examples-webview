//
//  Model.swift
//  rs-webview
//
//  Created by Erik Jakobsson on 2024-03-12.
//

public struct VindralChannelSwitch: Decodable {
  public let channelId: String
}

public enum VindralConnectionState: String {
  case connected = "connected"
  case disconnected = "disconnected"
  case connecting = "connecting"
}

public enum VindralContextSwitchState: String {
  case completed = "completed"
  case started = "started"
}

public enum VindralPlaybackState: String {
  case playing = "playing"
  case buffering = "buffering"
  case paused = "paused"
}

public struct VindralRenditionLevel: Decodable {
  public let audio: Rendition?
  public let video: Rendition?
}

public struct VindralTimedMetadata: Decodable {
  public let content: String
  public let timestamp: Double
  public let timestampAdded: Double
}

public struct VindralNeedsUserInputContext: Decodable {
  public let forAudio: Bool?
  public let forVideo: Bool?
}

public struct VindralVolumeState: Decodable {
  public let isMuted: Bool
  public let volume: Double
}

public struct VindralError {
  public let code: String
  public let message: String
  public let isFatal: Bool
}

public struct VindralStatistics: Decodable {
  public let audioBitRate: Double?
  public let audioCodec: String?
  public let audioRenditionId: Int?
  public let bufferTime: Double
  public let bufferTimeAdjustmentCount: Int
  public let bufferingEventsCount: Int
  public let bytesReceived: Int
  public let channelGroupId: String?
  public let channelId: String
  public let clientId: String
  public let connectCount: Int
  public let connectionAttemptCount: Int
  public let errorCount: Int
  public let estimatedBandwidth: Double
  public let expectedAudioBitRate: Double?
  public let expectedVideoBitRate: Double?
  public let fatalQosCount: Int
  public let frameRate: Array<Int>?
  public let ip: String?
  public let isAbrEnabled: Bool
  public let language: String?
  public let renditionLevelChangeCount: Int
  public let rtt: RttStats?
  public let sessionId: String?
  public let timeSpentBuffering: Double
  public let timeSpentRatio: [String: Double] // "timeSpentRatio": { "1160000": 0.2, "2260000": 0.8 }
  public let timeToFirstFrame: Double?
  public let uptime: Double
  public let url: String
  public let version: String
  public let videoBitRate: Double?
  public let videoCodec: String?
  public let videoHeight: Int?
  public let videoRenditionId: Int?
  public let videoWidth: Int?
}

public struct RttStats: Decodable {
  public let min: Double
  public let max: Double
  public let average: Double
}

public struct VindralJsChannel: Decodable {
  public let channelId: String
  public let name: String
  public let isLive: Bool
  public let thumbnailUrls: Array<String>
  public let renditions: Array<TypedRendition>
}

public struct TypedRendition: Decodable {
  public let type: String
  
  public let bitRate: Double
  public let codec: String
  public let id: UInt32
  public let codecString: String?
  
  // Audio specific
  public let channels: UInt32?
  public let sampleRate: UInt32?
  
  // Video specific
  public let frameRate: Array<UInt32>?
  public let height: UInt32?
  public let width: UInt32?
}

public struct Rendition: Decodable {
  public let bitRate: UInt64
  public let codec: String
  public let id: UInt32
  public let codecString: String?
  
  // Audio specific
  public let channels: UInt32?
  public let sampleRate: UInt32?
  
  // Video specific
  public let frameRate: Array<UInt32>?
  public let height: UInt32?
  public let width: UInt32?
}
  

