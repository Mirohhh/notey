package com.example.flutter_application_2

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TaskWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            // Get data written from Flutter
            val tasksText = widgetData.getString("tasks_data", "No tasks for today ✨")
            
            // Set data to the layout
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                setTextViewText(R.id.widget_tasks_text, tasksText)
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
