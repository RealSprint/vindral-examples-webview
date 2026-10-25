## Getting Started with the Android Project

These instructions will help you get the project up and running on your local machine for development and testing purposes.

### Prerequisites

Before you start, make sure you have installed:

- Android Studio
- Java Development Kit (JDK)

### Installation

**Open the project**

Launch Android Studio and choose 'Open an existing Android Studio project'. Navigate to the 'vindral-webview-example' directory and select it.

**Sync the project with Gradle files**

Android Studio will automatically sync the project with the Gradle files. If it doesn't, click on 'Sync Project with Gradle Files' in the toolbar.

**Run the project**

Click on the 'Run' button (the green arrow) or press Shift + F10. If you have a connected device or emulator it will run the app on it.

### Picture-in-Picture

Android WebView does not support the web Picture-in-Picture API, so the player's own PiP button stays hidden. The example puts the whole activity into Android Picture-in-Picture instead. All of it lives in `MainActivity.kt`:

- **Manifest:** the activity sets `android:supportsPictureInPicture="true"` and handles `screenSize|smallestScreenSize|screenLayout|orientation` itself, so entering and leaving PiP does not recreate the activity and reload the player.
- **Entering:** the PiP button in the control row, or leaving the app while the stream plays. Android 12 (API 31) and later enter by themselves through `setAutoEnterEnabled`; Android 8–11 (API 26–30) use `onUserLeaveHint`. Nothing happens before the first `playing` state or while paused.
- **In the PiP window:** the app hides its own controls and the player's, by setting the player's `--vindral-ui-display` CSS variable to `none`.
- **Keep the WebView running:** do not call `webView.onPause()` or `pauseTimers()` when the activity pauses. An activity in PiP is paused, but still visible.
- **Closing:** `onStop()` pauses the player. It runs when the user closes the PiP window, and also when the app goes to the background without PiP.

The PiP window is always 16:9. For streams with another aspect ratio, read `vindral.mediaElement.videoWidth` and `videoHeight` through the bridge and pass them to `setAspectRatio`. `setSourceRectHint` with the WebView's bounds gives a smoother enter animation.

Limits of the example: the PiP window has no play/pause buttons (expand it to control playback), audio focus and phone calls are not handled, and the activity's whole content becomes the PiP window.

Tested on Android 11 (API 30) and Android 14 (API 34) emulators.
