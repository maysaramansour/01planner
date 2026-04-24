package com.oneplanner.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TodayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.today_widget)

            val title = widgetData.getString("widget_title", "01-Planner")
            val date = widgetData.getString(
                "widget_date",
                SimpleDateFormat("EEE, MMM d", Locale.getDefault()).format(Date())
            )
            val content = widgetData.getString("widget_content", "Open 01-Planner to load your day")
            val summary = widgetData.getString("widget_summary", "Tap to open")
            val goal = widgetData.getString("widget_goal", "")

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_date, date)
            views.setTextViewText(R.id.widget_content, content)
            views.setTextViewText(R.id.widget_summary, summary)

            if (!goal.isNullOrBlank()) {
                views.setTextViewText(R.id.widget_goal, goal)
                views.setViewVisibility(R.id.widget_goal, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_goal, View.GONE)
            }

            val launchIntent: PendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
            views.setOnClickPendingIntent(R.id.widget_title, launchIntent)
            views.setOnClickPendingIntent(R.id.widget_content, launchIntent)
            views.setOnClickPendingIntent(R.id.widget_summary, launchIntent)
            views.setOnClickPendingIntent(R.id.widget_goal, launchIntent)

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
