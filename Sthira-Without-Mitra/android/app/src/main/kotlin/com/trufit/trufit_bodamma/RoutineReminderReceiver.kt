package com.trufit.trufit_bodamma

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/** Inexact routine alarms with an explicit first occurrence and calendar-week recurrence. */
class RoutineReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      synchronized(Companion) {
        if (intent.action != FIRE) {
            restore(context)
            return
        }
        val id = intent.getIntExtra("id", -1)
        val spec = read(context, id) ?: return
        try {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(NotificationChannel(CHANNEL, "Routine Reminders", NotificationManager.IMPORTANCE_HIGH))
            // Resolve the actual occurrence at delivery, so an old weekly payload
            // never sends a later tap into the first week's date.
            val date = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(spec.getLong("at"))
            val payload = JSONObject(spec.getString("payload")).put("date", date).put("recurring", false).toString()
            val builder = Notification.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_sthira)
                .setContentTitle(spec.getString("title"))
                .setContentText(spec.getString("body"))
                .setStyle(Notification.BigTextStyle().bigText(spec.getString("body")))
                .setAutoCancel(true)
                .setContentIntent(action(context, id, payload, "open", 0))
            if (spec.optBoolean("actions", true)) {
                builder.addAction(Notification.Action.Builder(null, "Snooze", action(context, id, payload, "snooze", 1)).build())
                builder.addAction(Notification.Action.Builder(null, "Skip Today", action(context, id, payload, "skip", 2)).build())
            }
            manager.notify(id, builder.build())
        } catch (_: Exception) {
            // Keep recurrence intact after revoked permissions; app surfaces permission state.
        } finally {
            if (spec.optBoolean("weekly")) {
                val next = Calendar.getInstance().apply { timeInMillis = spec.getLong("at"); add(Calendar.DAY_OF_MONTH, 7) }
                while (next.timeInMillis <= System.currentTimeMillis()) next.add(Calendar.DAY_OF_MONTH, 7)
                spec.put("at", next.timeInMillis)
                spec.put("localDate", SimpleDateFormat("yyyy-MM-dd", Locale.US).format(next.time))
                saveAndSchedule(context, spec)
            } else {
                prefs(context).edit().remove(id.toString()).commit()
            }
        }
      }
    }

    companion object {
        const val FIRE = "com.trufit.trufit_bodamma.ROUTINE_REMINDER"
        const val ACTION_EXTRA = "sthira_reminder_action"
        private const val CHANNEL = "routine_reminders"
        private fun prefs(context: Context) = context.getSharedPreferences("routine_schedules_v2", Context.MODE_PRIVATE)
        private fun read(context: Context, id: Int): JSONObject? = try { prefs(context).getString(id.toString(), null)?.let { JSONObject(it) } } catch (_: Exception) { null }
        private fun alarm(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(context, id,
            Intent(context, RoutineReminderReceiver::class.java).setAction(FIRE).putExtra("id", id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        private fun action(context: Context, id: Int, payload: String, action: String, offset: Int): PendingIntent {
            val data = JSONObject().put("id", id).put("payload", payload).put("action", action).toString()
            return PendingIntent.getActivity(context, id * 10 + offset,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP).putExtra(ACTION_EXTRA, data),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        @Synchronized fun saveAndSchedule(context: Context, spec: JSONObject) {
            val id = spec.getInt("id")
            require(id in 1000..7999)
            require(spec.getLong("at") > System.currentTimeMillis())
            prefs(context).edit().putString(id.toString(), spec.toString()).commit()
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, spec.getLong("at"), alarm(context, id))
        }
        @Synchronized fun cancel(context: Context, id: Int) {
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(alarm(context, id))
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(id)
            prefs(context).edit().remove(id.toString()).commit()
        }
        fun pending(context: Context): List<Int> = prefs(context).all.keys.mapNotNull { it.toIntOrNull() }
        @Synchronized fun restore(context: Context) {
            val now = System.currentTimeMillis()
            for (id in pending(context)) {
                val spec = read(context, id) ?: continue
                val date = spec.optString("localDate")
                val format = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { isLenient = false }
                val at = Calendar.getInstance()
                try {
                    // Rebuild wall-clock time after timezone changes. For a recurring
                    // alarm, retain the persisted weekday and find its next occurrence.
                    if (spec.optBoolean("weekly")) {
                        at.time = format.parse(date) ?: continue
                        at.set(Calendar.HOUR_OF_DAY, spec.getInt("hour"))
                        at.set(Calendar.MINUTE, spec.getInt("minute"))
                        at.set(Calendar.SECOND, 0); at.set(Calendar.MILLISECOND, 0)
                        while (at.timeInMillis <= now) at.add(Calendar.DAY_OF_MONTH, 7)
                    } else {
                        at.time = format.parse(date) ?: continue
                        at.set(Calendar.HOUR_OF_DAY, spec.getInt("hour")); at.set(Calendar.MINUTE, spec.getInt("minute"))
                        if (at.timeInMillis <= now) { cancel(context, id); continue }
                    }
                    spec.put("at", at.timeInMillis)
                    spec.put("localDate", format.format(at.time))
                    saveAndSchedule(context, spec)
                } catch (_: Exception) { cancel(context, id) }
            }
        }
    }
}
