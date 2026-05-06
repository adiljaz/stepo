package com.example.stepooo

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * StepWidgetProvider — Android AppWidgetProvider for the Stepooo home-screen widget.
 *
 * Data is written to SharedPreferences by the Dart [WidgetService] via the
 * home_widget package.  This provider reads those values and populates the
 * RemoteViews layout (step_widget.xml) whenever Android triggers an update.
 *
 * Keys (must match WidgetService.dart):
 *   steps    → Int  — today's committed steps
 *   goal     → Int  — user's daily goal
 *   progress → Int  — 0–100 percentage for ProgressBar
 *   calories → Int  — MET-based calorie burn
 */
class StepWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        val steps    = widgetData.getInt("steps", 0)
        val goal     = widgetData.getInt("goal", 8000)
        val progress = widgetData.getInt("progress", 0)
        val calories = widgetData.getInt("calories", 0)

        val views = RemoteViews(context.packageName, R.layout.step_widget)
        views.setTextViewText(R.id.widget_step_label, steps.toString())
        views.setTextViewText(R.id.widget_steps_unit, "/ $goal steps")
        views.setProgressBar(R.id.widget_progress, 100, progress, false)
        views.setTextViewText(R.id.widget_calories, "$calories kcal")

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
