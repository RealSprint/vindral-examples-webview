import { useEffect } from "react";
import { useCastChannel, useCastState } from "react-native-google-cast";

/**
 * This is a basic implementation of Google Cast integration with Vindral, using our custom receiver application.
 * The receiver application ID is `3F7711A9`.
 */
export function useVindralCast(channelId: string) {
  const castState = useCastState();
  const channel = useCastChannel("urn:x-cast:com.vindral.castdata");

  useEffect(() => {
    if (!channel || !channel.connected) {
      return;
    }
    if (castState === "connected") {
      console.log("sending start message");
      channel
        .sendMessage({
          type: "start",
          config: {
            options: {
              url: "https://lb.cdn.vindral.com",
              channelId,
            },
          },
        })
        .catch(console.error);
    }
  }, [castState, channelId, channel]);

  return castState;
}
