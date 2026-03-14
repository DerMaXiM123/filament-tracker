package com.filamenttracker.filament_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin

class FilamentWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.filament_widget)

            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                val total = widgetData.getString("total_filament", "0g") ?: "0g"
                val spoolCount = widgetData.getString("spool_count", "0") ?: "0"
                val lowStock = widgetData.getString("low_stock_count", "0") ?: "0"

                views.setTextViewText(R.id.widget_total, total)
                views.setTextViewText(R.id.widget_spool_count, spoolCount)

                val lowStockInt = lowStock.toIntOrNull() ?: 0
                if (lowStockInt > 0) {
                    views.setTextViewText(R.id.widget_low_stock, "⚠️ $lowStockInt unter 20%")
                    views.setTextColor(R.id.widget_low_stock, android.graphics.Color.parseColor("#FF5252"))
                } else {
                    views.setTextViewText(R.id.widget_low_stock, "✓ Alle OK")
                    views.setTextColor(R.id.widget_low_stock, android.graphics.Color.parseColor("#4CAF50"))
                }

                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
