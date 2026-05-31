package com.keyzzs.quota_analytics.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle

class QuotaWidgetProvider : AppWidgetProvider() {
    override fun onEnabled(context: Context) {
        QuotaWidgetUpdater.updateAll(context)
    }

    override fun onDisabled(context: Context) {
        // No app quota data is removed when the last widget is deleted.
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            QuotaWidgetConstants.ACTION_UPDATE_QUOTA_WIDGETS -> {
                QuotaWidgetUpdater.updateAll(context)
            }
            QuotaWidgetConstants.ACTION_WIDGET_OPEN_REFRESH_FLOW -> {
                context.startActivity(
                    QuotaWidgetUpdater.openAppIntent(
                        context,
                        target = QuotaWidgetConstants.TARGET_REFRESH_USAGE_PAGE,
                        action = QuotaWidgetConstants.ACTION_OPEN_REFRESH_FLOW,
                    ),
                )
            }
            else -> super.onReceive(context, intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        QuotaWidgetUpdater.updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        QuotaWidgetUpdater.updateWidgets(context, appWidgetManager, intArrayOf(appWidgetId))
    }
}
