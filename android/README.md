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

Android WebView does not support the web Picture-in-Picture API, so the example puts the whole activity into Android Picture-in-Picture, which needs Android 8.0 (API 26), the example's `minSdk`. The code is in `AndroidManifest.xml` and `MainActivity.kt`:

- **Manifest:** `android:supportsPictureInPicture="true"`, plus `configChanges` so that PiP does not recreate the activity and reload the player.
- **The player's PiP button:** a stand-in for the web API, injected with `WebViewCompat.addDocumentStartJavaScript` from `androidx.webkit`, makes the player show its button and calls the app. It is a workaround that covers only what the player uses. A WebView without `DOCUMENT_START_SCRIPT` shows no button.
- **Home:** enters PiP while the stream plays, through `setAutoEnterEnabled` on Android 12 and later and `onUserLeaveHint` on Android 8–11.
- **In the PiP window:** the app hides its control row, and the player's controls through an `android-pip` class with an `!important` `--vindral-ui-display: none` rule, so a `player.controlsEnabled=false` setting survives.
- **Keep the WebView running:** do not call `webView.onPause()` or `pauseTimers()`. An activity in PiP is paused, but still visible.
- **Closing:** `onStop()` pauses the player, also when the user closes the PiP window. A `playing` state that arrives while the activity is stopped is paused again, because the SDK can resume playback when PiP ends.

The PiP window is 16:9. For other aspect ratios, pass the video's size to `setAspectRatio`: check that `vindral.mediaElement` is a video with a size above 0, and clamp the ratio to 1:2.39–2.39:1, or it throws.

Limits of the example: the PiP window has no play/pause buttons (expand it to control playback), audio focus and phone calls are not handled, and the activity's whole content becomes the PiP window.

### Fullscreen

The player's fullscreen button needs a `WebChromeClient` that implements `onShowCustomView` and `onHideCustomView`; without one, the button does nothing. The example puts the view it gets on top of the activity, hides the system bars, and turns the screen to landscape. WebView leaves fullscreen on Back by itself. Picture-in-Picture from fullscreen shows the fullscreen video.
