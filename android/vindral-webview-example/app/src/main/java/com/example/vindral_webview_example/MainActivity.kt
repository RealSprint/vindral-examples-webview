package com.example.vindral_webview_example

import android.app.PictureInPictureParams
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.Rational
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.annotation.ChecksSdkIntAtLeast
import androidx.annotation.RequiresApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.example.vindral_webview_example.ui.theme.VindralwebviewexampleTheme
import com.google.gson.Gson

enum class VindralPlaybackState(val state: String) {
    PLAYING("playing"),
    BUFFERING("buffering"),
    PAUSED("paused")
}

data class VindralVolumeState(val isMuted: Boolean, val volume: Double)
data class VindralError(val code: String, val message: String, val isFatal: Boolean)

class MainActivity : ComponentActivity() {
    private val gson = Gson()
    private lateinit var webView: WebView
    private var url =
        "https://player.vindral.com/?core.url=https://lb.cdn.vindral.com&core.channelId=vindral_demo1_ci_099ee1fa-80f3-455e-aa23-3d184e93e04f"

    // Picture-in-picture is only offered once playback has started, and never while the activity is stopped.
    private val canEnterPip = mutableStateOf(false)
    private val isInPip = mutableStateOf(false)
    private var isStopped = false

    private val pipSupported: Boolean
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.O)
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

    companion object {
        private const val TAG = "VindralPip"

        // JavaScript code to handle Vindral events and communicate with the Android interface.
        // It attaches to an instance that already exists as well as to one created later.
        private const val JS_INTERFACE = "Android"
        private const val JS_CODE =
        """
        (() => {
            const style = document.createElement("style")
            style.textContent = ".android-pip vindral-player { --vindral-ui-display: none !important; }"
            document.head.appendChild(style)
            let attached
            const attach = (vindral) => {
                if (!vindral || vindral === attached) return
                attached = vindral
                vindral.on("playback state", (state) => $JS_INTERFACE.onPlaybackState(state))
                vindral.on("volume state", (state) => $JS_INTERFACE.onVolumeState(JSON.stringify(state)))
                vindral.on("error", (error) => $JS_INTERFACE.onError(JSON.stringify(error)))
                $JS_INTERFACE.onPlaybackState(vindral.playbackState)
            }
            window.addEventListener("vindral-instance-ready", (event) => attach(event.detail))
            attach(window.vindral)
        })()
        """

        // Hides the player's controls in the PiP window. The class rule is !important, so it wins over
        // the inline value the player sets for player.controlsEnabled without overwriting it.
        private fun playerUiScript(hidden: Boolean) =
            "document.documentElement.classList.toggle('android-pip', $hidden)"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            WebView.setWebContentsDebuggingEnabled(true)
        }

        isInPip.value = isInPictureInPictureMode
        addOnPictureInPictureModeChangedListener { info ->
            Log.d(TAG, "picture-in-picture: ${info.isInPictureInPictureMode}")
            isInPip.value = info.isInPictureInPictureMode
            webView.evaluateJavascript(playerUiScript(info.isInPictureInPictureMode), null)
        }

        setContent {
            VindralwebviewexampleTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    WebViewWithControls(url)
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        isStopped = false
    }

    // Also runs when the user closes the picture-in-picture window. Do not pause the WebView
    // itself in onPause: the activity is paused, but still visible, while in picture-in-picture.
    override fun onStop() {
        super.onStop()
        isStopped = true
        setCanEnterPip(false)
        Log.d(TAG, "stopped, pausing playback")
        pause()
    }

    override fun onDestroy() {
        if (::webView.isInitialized) webView.destroy()
        super.onDestroy()
    }

    // Android 12+ enters picture-in-picture by itself through setAutoEnterEnabled.
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (pipSupported && Build.VERSION.SDK_INT <= Build.VERSION_CODES.R && canEnterPip.value) {
            enterPip()
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun pipParams(): PictureInPictureParams {
        val builder = PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(canEnterPip.value)
        }
        return builder.build()
    }

    private fun setCanEnterPip(value: Boolean) {
        if (canEnterPip.value == value) return
        canEnterPip.value = value
        if (pipSupported) setPictureInPictureParams(pipParams())
    }

    private fun enterPip() {
        if (!pipSupported) return
        val entered = try {
            enterPictureInPictureMode(pipParams())
        } catch (error: IllegalStateException) {
            Log.w(TAG, "picture-in-picture refused", error)
            false
        }
        if (!entered) {
            Log.w(TAG, "picture-in-picture unavailable")
            Toast.makeText(this, "Picture-in-picture is unavailable", Toast.LENGTH_SHORT).show()
        }
    }

    private fun play() {
        webView.evaluateJavascript("window.vindral?.play()", null)
    }

    private fun pause() {
        if (::webView.isInitialized) webView.evaluateJavascript("window.vindral?.pause()", null)
    }

    @android.webkit.JavascriptInterface
    fun onPlaybackState(state: String) = runOnUiThread {
        Log.d(TAG, "playback state: $state")
        // Unknown states are ignored, so a newer player cannot crash the app.
        when (state) {
            // A player that starts while the app is in the background is paused again.
            VindralPlaybackState.PLAYING.state -> if (isStopped) pause() else setCanEnterPip(true)
            VindralPlaybackState.PAUSED.state -> setCanEnterPip(false)
        }
    }

    @android.webkit.JavascriptInterface
    fun onVolumeState(json: String) {
        val volumeState = gson.fromJson(json, VindralVolumeState::class.java)
        Toast.makeText(
            this,
            "Volume state: isMuted=${volumeState.isMuted}, volume=${volumeState.volume}",
            Toast.LENGTH_SHORT
        ).show()
    }

    @android.webkit.JavascriptInterface
    fun onError(json: String) {
        val error = gson.fromJson(json, VindralError::class.java)
        Toast.makeText(this, "Error: $error", Toast.LENGTH_SHORT).show()
    }

    @Composable
    fun WebViewComposable(url: String) {
        this.webView = remember {
            WebView(this).apply {
                settings.javaScriptEnabled = true
                settings.mediaPlaybackRequiresUserGesture = false
                addJavascriptInterface(this@MainActivity, JS_INTERFACE)

                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        Log.d(TAG, "bridge injected")
                        webView.evaluateJavascript(
                            JS_CODE,
                            null
                        )
                        webView.evaluateJavascript(playerUiScript(isInPip.value), null)
                    }
                }
                loadUrl(url)
            }
        }
        webView.layoutParams = android.view.ViewGroup.LayoutParams(
            android.view.ViewGroup.LayoutParams.MATCH_PARENT,
            android.view.ViewGroup.LayoutParams.MATCH_PARENT
        )
        AndroidView({ webView })
    }

    @Composable
    fun WebViewWithControls(url: String) {
        Box(modifier = Modifier.fillMaxSize()) {
            WebViewComposable(url)
            if (!isInPip.value) Row(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp)
                    .background(Color.Black.copy(alpha = 0.7f))
                    .fillMaxWidth()
                    .wrapContentHeight(),
                horizontalArrangement = Arrangement.Center
            ) {
                Button(onClick = {
                    play()
                }) {
                    Text("Play")
                }
                Spacer(modifier = Modifier.width(16.dp))
                Button(onClick = {
                    pause()
                }) {
                    Text("Pause")
                }
                if (pipSupported) {
                    Spacer(modifier = Modifier.width(16.dp))
                    Button(onClick = { enterPip() }, enabled = canEnterPip.value) {
                        Text("PiP")
                    }
                }
            }
        }
    }
}
