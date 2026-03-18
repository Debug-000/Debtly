package com.example.debt_tracker

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "debtly/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "clearNotificationPluginCache" -> {
                        try {
                            applicationContext
                                .getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE)
                                .edit()
                                .clear()
                                .apply()

                            applicationContext
                                .getSharedPreferences("notification_plugin_cache", Context.MODE_PRIVATE)
                                .edit()
                                .clear()
                                .apply()

                            result.success(true)
                        } catch (e: Exception) {
                            result.error("native_clear_failed", e.message, null)
                        }
                    }
                    "openAppNotificationSettings" -> {
                        try {
                            val intent = Intent().apply {
                                action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                                putExtra(Settings.EXTRA_APP_PACKAGE, applicationContext.packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("open_notifications_failed", e.message, null)
                        }
                    }
                    "openExactAlarmSettings" -> {
                        try {
                            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                    data = Uri.parse("package:${applicationContext.packageName}")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                            } else {
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                    data = Uri.parse("package:${applicationContext.packageName}")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("open_exact_alarm_failed", e.message, null)
                        }
                    }
                    "openBatteryOptimizationSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("open_battery_settings_failed", e.message, null)
                        }
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        try {
                            val powerManager = applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
                            result.success(powerManager.isIgnoringBatteryOptimizations(applicationContext.packageName))
                        } catch (e: Exception) {
                            result.error("battery_optimization_check_failed", e.message, null)
                        }
                    }
                    "deviceManufacturer" -> {
                        result.success(Build.MANUFACTURER ?: "")
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
