package com.trufit.trufit_bodamma

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import org.json.JSONObject

class MainActivity : FlutterFragmentActivity() {
    private var notificationChannel: MethodChannel? = null
    @Volatile private var routinesReady = false
    private val channelName = "com.trufit.trufit_bodamma/screentime"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        notificationChannel = MethodChannel(messenger, "com.trufit.trufit_bodamma/routines", StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue()).also { channel ->
            channel.setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "schedule" -> { RoutineReminderReceiver.saveAndSchedule(applicationContext, JSONObject(call.arguments as Map<*, *>)); result.success(null) }
                        "cancel" -> { RoutineReminderReceiver.cancel(applicationContext, call.argument<Int>("id")!!); result.success(null) }
                        "dismiss" -> { (getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager).cancel(call.argument<Int>("id")!!); result.success(null) }
                        "pending" -> result.success(RoutineReminderReceiver.pending(applicationContext))
                        "launchAction" -> runOnUiThread {
                            routinesReady = true
                            val action = intent.getStringExtra(RoutineReminderReceiver.ACTION_EXTRA)
                            intent.removeExtra(RoutineReminderReceiver.ACTION_EXTRA)
                            result.success(action)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) { result.error("REMINDER_FAILED", "Reminder could not be scheduled", null) }
            }
        }
        // Usage event queries may be expensive. Keep them off the platform UI thread.
        MethodChannel(messenger, channelName, StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue())
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getScreenTime" -> result.success(getScreenTimeResult(call.argument<String>("date")))
                    "checkPermission" -> result.success(checkUsageStatsPermission())
                    "openUsageSettings" -> runOnUiThread {
                        try {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK })
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("SETTINGS_UNAVAILABLE", "Usage access settings could not be opened", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = intent.getStringExtra(RoutineReminderReceiver.ACTION_EXTRA) ?: return
        if (!routinesReady) return // launchAction drains it after Dart attaches.
        notificationChannel?.invokeMethod("action", action, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (getIntent().getStringExtra(RoutineReminderReceiver.ACTION_EXTRA) == action) getIntent().removeExtra(RoutineReminderReceiver.ACTION_EXTRA)
            }
            override fun error(code: String, message: String?, details: Any?) { /* Retain for next initialization. */ }
            override fun notImplemented() { routinesReady = false }
        })
    }

    private fun checkUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getScreenTimeResult(requestedDate: String?): Map<String, Any?> {
        return try {
            if (!checkUsageStatsPermission()) return mapOf("status" to "denied")
            val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { isLenient = false }
            val day = Calendar.getInstance()
            if (requestedDate != null) {
                val parsed = formatter.parse(requestedDate) ?: return mapOf("status" to "failed")
                if (formatter.format(parsed) != requestedDate) return mapOf("status" to "failed")
                day.time = parsed
            }
            day.set(Calendar.HOUR_OF_DAY, 0)
            day.set(Calendar.MINUTE, 0)
            day.set(Calendar.SECOND, 0)
            day.set(Calendar.MILLISECOND, 0)
            val start = day.timeInMillis
            val now = System.currentTimeMillis()
            if (start > now) return mapOf("status" to "unavailable")
            val nextDay = (day.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, 1) }
            val end = minOf(now, nextDay.timeInMillis)
            val lookback = (day.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, -1) }.timeInMillis
            val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val events = manager.queryEvents(lookback, end) ?: return mapOf("status" to "unavailable")
            val event = UsageEvents.Event()
            val foreground = mutableSetOf<String>()
            var intervalStart: Long? = null
            var total = 0L
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val at = event.timeStamp.coerceAtMost(end)
                val wasActive = foreground.isNotEmpty()
                val key = "${event.packageName}/${event.className}"
                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> foreground.add(key)
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> foreground.remove(key)
                    // Stop open intervals when the screen locks/switches off or device stops.
                    UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                    UsageEvents.Event.KEYGUARD_SHOWN,
                    UsageEvents.Event.DEVICE_SHUTDOWN -> foreground.clear()
                }
                val isActive = foreground.isNotEmpty()
                if (!wasActive && isActive) intervalStart = at
                if (wasActive && !isActive) {
                    total += (at - maxOf(start, intervalStart ?: at)).coerceAtLeast(0L)
                    intervalStart = null
                }
            }
            if (foreground.isNotEmpty()) total += (end - maxOf(start, intervalStart ?: end)).coerceAtLeast(0L)
            // Unioned foreground intervals cannot exceed the actual calendar-day bounds.
            total = total.coerceIn(0L, end - start)
            mapOf("status" to "success", "minutes" to (total / 60000).toInt(),
                "measuredDate" to formatter.format(day.time), "timestamp" to now)
        } catch (error: Exception) {
            mapOf("status" to "failed", "error" to "Usage measurement unavailable")
        }
    }
}
