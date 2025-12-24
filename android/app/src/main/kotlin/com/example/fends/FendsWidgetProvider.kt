package com.example.fends

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class FendsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, android.R.layout.simple_list_item_1)
            
            val prefs = HomeWidgetPlugin.getData(context)
            val balance = prefs.getString("balance", "$0")
            
            views.setTextViewText(android.R.id.text1, balance)
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}