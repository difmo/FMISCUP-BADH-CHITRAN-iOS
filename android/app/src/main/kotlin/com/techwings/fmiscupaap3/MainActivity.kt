package com.techwings.fmiscupaap3
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.techwings.fmiscupaap3" // same as in Dart

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "isDeveloperModeEnabled") {

                val isEnabled = Settings.Secure.getInt(
                    contentResolver, Settings.Secure.DEVELOPMENT_SETTINGS_ENABLED, 0
                ) != 0
                result.success(isEnabled)

            }
            if (call.method == "openDeveloperSettings") {
                try {
                    val intent =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) { // API 22+
                            Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                        } else {
                            Intent(Settings.ACTION_SETTINGS) // fallback to general settings
                        }
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Cannot open developer settings", null)
                }
            } else {
                result.notImplemented()
            }
        }

        fun isDeveloperModeEnabled(context: Context): Boolean {
            return Settings.Secure.getInt(
                context.contentResolver, Settings.Secure.DEVELOPMENT_SETTINGS_ENABLED, 0
            ) != 0
        }
    }
}
