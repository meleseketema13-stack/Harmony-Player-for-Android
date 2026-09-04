package com.harmonyplayer.harmony_player

import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileInputStream
import java.io.InputStream

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Exposes bounded reads of media bytes (for embedded lyrics/tags) to
        // Dart. The Dart side requests only the byte ranges it needs, so large
        // files are never read into memory whole.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.harmonyplayer.harmony_player/media",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "readFile" -> {
                    val uri = call.argument<String>("uri")
                    val start = call.argument<Int>("start") ?: 0
                    val length = call.argument<Int>("length")
                    if (uri.isNullOrEmpty()) {
                        result.error("badArgs", "uri is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val stream = openStream(uri)
                        if (stream == null) {
                            result.error("notFound", "File not found: $uri", null)
                        } else {
                            stream.use {
                                if (start > 0) {
                                    val skipped = it.skip(start.toLong())
                                    if (skipped < start.toLong()) {
                                        result.success(ByteArray(0))
                                        return@setMethodCallHandler
                                    }
                                }
                                val bytes = if (length != null) {
                                    it.readNBytes(length)
                                } else {
                                    it.readBytes()
                                }
                                result.success(bytes)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("readFailed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openStream(uri: String): InputStream? {
        return if (uri.startsWith("content://")) {
            contentResolver.openInputStream(Uri.parse(uri))
        } else {
            val path = if (uri.startsWith("file://")) {
                Uri.parse(uri).path ?: return null
            } else {
                uri
            }
            val file = java.io.File(path)
            if (!file.exists()) return null
            FileInputStream(file)
        }
    }
}
