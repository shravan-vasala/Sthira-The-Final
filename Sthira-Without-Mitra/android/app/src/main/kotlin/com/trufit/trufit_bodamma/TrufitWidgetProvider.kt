package com.trufit.trufit_bodamma

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.util.Log

class TrufitWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle?) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        updateWidget(context, appWidgetManager, appWidgetId, widgetData)
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int, widgetData: SharedPreferences) {
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val jsonStr = widgetData.getString("widget_data", "{}") ?: "{}"
        
        var date = ""
        var updatedAt = "--:--"
        var steps: Int? = null
        var stepGoal: Int? = null
        var mealsLogged = 0
        var totalMeals = 0
        var habitsDone = 0
        var totalHabits = 0
        var energy: Double? = null
        var protein: Double? = null
        var workoutTitle = "Open app"
        var workoutStatus = "to refresh"

        try {
            val json = JSONObject(jsonStr)
            date = json.optString("date", "")
            if (date == todayStr) {
                updatedAt = json.optString("updatedAt", "--:--")
                steps = (json.opt("steps") as? Number)?.toInt()?.takeIf { it >= 0 }
                stepGoal = (json.opt("stepGoal") as? Number)?.toInt()?.takeIf { it > 0 }
                mealsLogged = json.optInt("mealsLogged", 0)
                totalMeals = json.optInt("totalMeals", 0)
                habitsDone = json.optInt("habitsDone", 0)
                totalHabits = json.optInt("totalHabits", 0)
                energy = (json.opt("energy") as? Number)?.toDouble()?.takeIf { it.isFinite() && it >= 0 }
                protein = (json.opt("protein") as? Number)?.toDouble()?.takeIf { it.isFinite() && it >= 0 }
                workoutTitle = json.optString("workoutTitle", "Workout")
                workoutStatus = json.optString("workoutStatus", "Pending")
            }
        } catch (e: Exception) {
            Log.e("TrufitWidgetProvider", "Error parsing widget data", e)
        }

        fun populateShared(views: RemoteViews) {
            views.setTextViewText(R.id.tv_updated_at, if (date == todayStr) "Updated $updatedAt" else "Open to refresh")

            if (steps == null) {
                views.setTextViewText(R.id.tv_steps_value, "—")
                views.setViewVisibility(R.id.tv_steps_goal, View.GONE)
                views.setViewVisibility(R.id.pb_steps, View.GONE)
            } else {
                val stepCountStr = String.format("%,d", steps)
                views.setTextViewText(R.id.tv_steps_value, stepCountStr)
                if (stepGoal != null && stepGoal > 0) {
                    views.setViewVisibility(R.id.tv_steps_goal, View.VISIBLE)
                    views.setTextViewText(R.id.tv_steps_goal, "Goal ${String.format("%,d", stepGoal)}")
                    val progress = ((steps!!.toDouble() / stepGoal!!.toDouble()) * 100).toInt().coerceIn(0, 100)
                    views.setViewVisibility(R.id.pb_steps, View.VISIBLE)
                    views.setProgressBar(R.id.pb_steps, 100, progress, false)
                } else {
                    views.setViewVisibility(R.id.tv_steps_goal, View.GONE)
                    views.setViewVisibility(R.id.pb_steps, View.GONE)
                }
            }
        }

        fun populateCompact(views: RemoteViews, reqBase: Int) {
            populateShared(views)
            // Compact cards prioritize the count; the full target remains in accessibility text.
            views.setViewVisibility(R.id.tv_steps_goal, View.GONE)
            views.setContentDescription(R.id.widget_root_compact,
                if (steps == null) "Today. Steps not recorded. Open Home"
                else "Today. $steps steps" + (stepGoal?.let { ", goal $it" } ?: "") + ". Open Home")
            val baseIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("trufit://app/widget/home")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val rootPi = PendingIntent.getActivity(context, reqBase, baseIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_root_compact, rootPi)
        }

        fun populateStandard(views: RemoteViews, reqBase: Int, rootId: Int = R.id.widget_root_standard) {
            populateShared(views)
            if (date == todayStr) {
                views.setTextViewText(R.id.tv_meals_value, "$mealsLogged/$totalMeals")
                views.setTextViewText(R.id.tv_habits_value, "$habitsDone/$totalHabits")
            } else {
                views.setTextViewText(R.id.tv_meals_value, "-/-")
                views.setTextViewText(R.id.tv_habits_value, "-/-")
            }

            val baseIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("trufit://app/widget/home")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            
            views.setContentDescription(R.id.widget_steps_area,
                if (steps == null) "Steps not recorded. Open progress"
                else "$steps steps" + (stepGoal?.let { ", goal $it" } ?: "") + ". Open progress")
            views.setContentDescription(R.id.widget_meals_area,
                if (date == todayStr) "$mealsLogged of $totalMeals meals logged. Open meals"
                else "Meals unavailable. Open meals")
            views.setContentDescription(R.id.widget_habits_area,
                if (date == todayStr) "$habitsDone of $totalHabits habits done. Open Home"
                else "Habits unavailable. Open Home")
            val stepsIntent = Intent(baseIntent).apply { data = Uri.parse("trufit://app/widget/steps") }
            val stepsPi = PendingIntent.getActivity(context, reqBase + 1, stepsIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_steps_area, stepsPi)

            val mealsIntent = Intent(baseIntent).apply { data = Uri.parse("trufit://app/widget/meals") }
            val mealsPi = PendingIntent.getActivity(context, reqBase + 2, mealsIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_meals_area, mealsPi)

            val habitsIntent = Intent(baseIntent).apply { data = Uri.parse("trufit://app/widget/home") }
            val habitsPi = PendingIntent.getActivity(context, reqBase + 3, habitsIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_habits_area, habitsPi)

            val rootPi = PendingIntent.getActivity(context, reqBase, baseIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(rootId, rootPi)
        }

        fun populateExpanded(views: RemoteViews, reqBase: Int) {
            populateStandard(views, reqBase, R.id.widget_root_expanded)

            if (energy != null || protein != null) {
                views.setViewVisibility(R.id.widget_nutrition_area, View.VISIBLE)
                views.setTextViewText(R.id.tv_nutrition_energy, if (energy != null) "${energy!!.toInt()} kcal" else "-- kcal")
                views.setTextViewText(R.id.tv_nutrition_protein, if (protein != null) "${protein!!.toInt()}g protein" else "--g protein")
            } else {
                views.setViewVisibility(R.id.widget_nutrition_area, View.GONE)
            }

            views.setTextViewText(R.id.tv_workout_title, workoutTitle)
            views.setTextViewText(R.id.tv_workout_sub, workoutStatus)

            val baseIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("trufit://app/widget/home")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            
            val workoutIntent = Intent(baseIntent).apply { data = Uri.parse("trufit://app/widget/workout") }
            val workoutPi = PendingIntent.getActivity(context, reqBase + 4, workoutIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_workout_area, workoutPi)

            val rootPi = PendingIntent.getActivity(context, reqBase, baseIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_root_expanded, rootPi)
        }

        val fontScale = context.resources.configuration.fontScale.coerceAtLeast(1f)
        val standardWidth = 300f * fontScale
        val standardHeight = 220f * fontScale
        val expandedHeight = 340f * fontScale
        val remoteViews: RemoteViews = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val compact = RemoteViews(context.packageName, R.layout.widget_layout_compact).apply { populateCompact(this, 100) }
            val standard = RemoteViews(context.packageName, R.layout.widget_layout_standard).apply { populateStandard(this, 200) }
            val expanded = RemoteViews(context.packageName, R.layout.widget_layout_expanded).apply { populateExpanded(this, 300) }
            
            val viewMapping = mapOf(
                SizeF(160f, 180f) to compact,
                SizeF(standardWidth, standardHeight) to standard,
                SizeF(standardWidth, expandedHeight) to expanded
            )
            RemoteViews(viewMapping)
        } else {
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

            if (minHeight >= expandedHeight && minWidth >= standardWidth) {
                RemoteViews(context.packageName, R.layout.widget_layout_expanded).apply { populateExpanded(this, 300) }
            } else if (minWidth >= standardWidth && minHeight >= standardHeight) {
                RemoteViews(context.packageName, R.layout.widget_layout_standard).apply { populateStandard(this, 200) }
            } else {
                RemoteViews(context.packageName, R.layout.widget_layout_compact).apply { populateCompact(this, 100) }
            }
        }

        appWidgetManager.updateAppWidget(widgetId, remoteViews)
    }
}
