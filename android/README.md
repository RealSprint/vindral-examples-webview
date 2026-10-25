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

Android WebView does not support the web Picture-in-Picture API, so the player's own PiP button stays hidden. The example puts the whole activity into Android Picture-in-Picture instead. The code is in `AndroidManifest.xml` and `MainActivity.kt`:

- **Manifest:** the activity sets `android:supportsPictureInPicture="true"` and handles `screenSize|smallestScreenSize|screenLayout|orientation` itself, so entering and leaving PiP does not recreate the activity and reload the player.
- **Entering:** the PiP button in the control row, or pressing Home or switching apps while the stream plays (Back does not enter PiP). Android 12 (API 31) and later enter by themselves through `setAutoEnterEnabled`; Android 8–11 (API 26–30) use `onUserLeaveHint`. Nothing happens while paused, or before a newly loaded page reports `playing`. If the user has turned PiP off for the app, only the button shows a message.
- **In the PiP window:** the app hides its own control row. It hides the player's controls by toggling an `android-pip` class on the page, which an injected `!important` rule turns into `--vindral-ui-display: none`. This keeps a `player.controlsEnabled=false` setting intact after leaving PiP.
- **Keep the WebView running:** do not call `webView.onPause()` or `pauseTimers()` when the activity pauses. An activity in PiP is paused, but still visible.
- **Closing:** `onStop()` pauses the player. It runs when the user closes the PiP window, and also when the app goes to the background without PiP.

The PiP window is always 16:9. For streams with another aspect ratio, read `vindral.mediaElement.videoWidth` and `videoHeight` through the bridge and pass them to `setAspectRatio`. Check that `mediaElement` is a video element (it can be a canvas) and that both values are above 0, and clamp the ratio to Android's limits (1:2.39 to 2.39:1), or `setAspectRatio` throws. `setSourceRectHint` with the WebView's bounds gives a smoother enter animation.

Limits of the example: the PiP window has no play/pause buttons (expand it to control playback), audio focus and phone calls are not handled, and the activity's whole content becomes the PiP window.

Tested on Android 11 (API 30) and Android 14 (API 34) emulators.
