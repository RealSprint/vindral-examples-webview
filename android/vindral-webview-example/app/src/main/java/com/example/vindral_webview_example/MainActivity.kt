package com.example.vindral_webview_example

import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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

    companion object {
        private const val JS_INTERFACE = "Android"
        private const val JS_CODE =
            """
            async function run() {
                let loops = 0
                while (!window.vindral) {
                    if (loops > 20) {
                      throw new Error("Could not find window.vindral")
                    }
                    await new Promise(r => setTimeout(r, 100))
                    loops++
                }
                
                window.vindral.on("playback state", (state) => window.$JS_INTERFACE.onPlaybackState(state))
                window.vindral.on("volume state", (state) => window.$JS_INTERFACE.onVolumeState(JSON.stringify(state)))
                window.vindral.on("error", (error) => window.$JS_INTERFACE.onError(JSON.stringify(error)))
            }
            run()
        """
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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

    private fun play() {
        webView.evaluateJavascript("window.vindral.play()", null)
    }

    private fun pause() {
        webView.evaluateJavascript("window.vindral.pause()", null)
    }

    @android.webkit.JavascriptInterface
    fun onPlaybackState(state: String) {
        val playbackState = VindralPlaybackState.valueOf(state.uppercase())
        Toast.makeText(
            this,
            "Playback state: ${playbackState.state}",
            Toast.LENGTH_SHORT
        ).show()
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
                        webView.evaluateJavascript(
                            JS_CODE,
                            null
                        )
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
            Row(
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
            }
        }
    }
}
