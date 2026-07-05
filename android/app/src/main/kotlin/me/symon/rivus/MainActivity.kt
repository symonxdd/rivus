package me.symon.rivus

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val mediaStoreAudioChannel = "me.symon.rivus/media_store_audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            mediaStoreAudioChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "querySongs" -> result.success(MediaStoreAudioQuery(contentResolver).querySongs())
                else -> result.notImplemented()
            }
        }
    }
}
