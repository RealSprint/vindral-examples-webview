import { StatusBar } from "expo-status-bar";
import React, { useRef } from "react";
import { Button, StyleSheet, View } from "react-native";
import { CastButton } from "react-native-google-cast";
import WebView, { WebViewMessageEvent } from "react-native-webview";
import { useVindralCast } from "./cast";

interface Message {
  type: "playback state" | "volume state" | "error";
}

interface PlaybackStateMessage extends Message {
  type: "playback state";
  state: "buffering" | "playing" | "paused";
}

interface VolumeStateMessage extends Message {
  type: "volume state";
  state: {
    volume: number;
    isMuted: boolean;
  };
}

interface ErrorMessage extends Message {
  type: "error";
  error: {
    code: string;
    message: string;
    isFatal: boolean;
  };
}

const script = `
  window.addEventListener("vindral-instance-ready", (event) => {
    event.detail.on("playback state", (state) => {
      window.ReactNativeWebView.postMessage(JSON.stringify({
        type: "playback state",
        state,
      }))
    })
    event.detail.on("volume state", (state) => {
      window.ReactNativeWebView.postMessage(JSON.stringify({
        type: "volume state",
        state,
      }))
    })
    event.detail.on("error", (error) => {
      window.ReactNativeWebView.postMessage(JSON.stringify({
        type: "error",
        error,
      }))
    })
  })

  true  // note: this is required, or you'll sometimes get silent failures
`;

export default function App() {
  const webViewRef = useRef<WebView>(null);

  const onMessage = (event: WebViewMessageEvent) => {
    const message = JSON.parse(event.nativeEvent.data);

    switch (message.type) {
      case "playback state": {
        const playbackStateMessage = message as PlaybackStateMessage;
        console.log("playback state", playbackStateMessage.state);
        break;
      }
      case "volume state": {
        const volumeStateMessage = message as VolumeStateMessage;
        console.log("volume state", volumeStateMessage.state);
        break;
      }
      case "error": {
        const errorMessage = message as ErrorMessage;
        console.error("error", errorMessage.error);
        break;
      }
      default:
        console.log("unknown message", message);
    }
  };

  const channelId = "vindral_demo1_ci_099ee1fa-80f3-455e-aa23-3d184e93e04f";
  useVindralCast(channelId);

  return (
    <View style={styles.container}>
      <StatusBar style="auto" />
      <WebView
        ref={webViewRef}
        source={{
          uri: `https://player.vindral.com/?channelId=${channelId}`,
        }}
        allowsFullscreenVideo
        mediaPlaybackRequiresUserAction={false}
        allowsInlineMediaPlayback
        javaScriptEnabled
        injectedJavaScript={script}
        onMessage={onMessage}
      />
      <View style={styles.controls}>
        <Button
          title="Play"
          onPress={() =>
            webViewRef.current?.injectJavaScript("window.vindral.play()")
          }
        />
        <Button
          title="Pause"
          onPress={() =>
            webViewRef.current?.injectJavaScript("window.vindral.pause()")
          }
        />
        <CastButton
          style={{
            padding: 10,
          }}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },

  controls: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    flexDirection: "row",
    justifyContent: "center",
    padding: 20,
    gap: 20,
  },
});
