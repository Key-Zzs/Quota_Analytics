package com.keyzzs.quota_analytics.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.keyzzs.quota_analytics.MainActivity
import com.keyzzs.quota_analytics.R
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

object QuotaWidgetUpdater {
    private const val MEDIUM_MIN_WIDTH_DP = 220
    private const val STALE_AFTER_MINUTES = 30L
    private const val REQUEST_OPEN_QUOTA = 100
    private const val REQUEST_OPEN_REFRESH = 101

    fun updateAll(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val ids = appWidgetManager.getAppWidgetIds(
            ComponentName(context, QuotaWidgetProvider::class.java),
        )
        updateWidgets(context, appWidgetManager, ids)
    }

    fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    fun installedWidgetCount(context: Context): Int {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        return appWidgetManager.getAppWidgetIds(
            ComponentName(context, QuotaWidgetProvider::class.java),
        ).size
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val isMedium = options.isMediumWidget()
        val layoutId = if (isMedium) {
            R.layout.quota_widget_medium
        } else {
            R.layout.quota_widget_small
        }
        val views = RemoteViews(context.packageName, layoutId)
        val state = QuotaWidgetSummaryReader(context).read()

        if (isMedium) {
            bindMedium(context, views, state)
        } else {
            bindSmall(context, views, state)
        }

        views.setOnClickPendingIntent(
            R.id.quota_widget_root,
            openAppPendingIntent(
                context,
                target = QuotaWidgetConstants.TARGET_QUOTA,
                action = QuotaWidgetConstants.ACTION_OPEN_QUOTA,
                requestCode = REQUEST_OPEN_QUOTA,
            ),
        )
        views.setOnClickPendingIntent(
            R.id.quota_widget_refresh,
            openAppPendingIntent(
                context,
                target = QuotaWidgetConstants.TARGET_REFRESH_USAGE_PAGE,
                action = QuotaWidgetConstants.ACTION_OPEN_REFRESH_FLOW,
                requestCode = REQUEST_OPEN_REFRESH,
            ),
        )
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun Bundle?.isMediumWidget(): Boolean {
        val minWidth = this?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
        return minWidth >= MEDIUM_MIN_WIDTH_DP
    }

    private fun bindSmall(
        context: Context,
        views: RemoteViews,
        state: QuotaWidgetReadResult,
    ) {
        views.setTextViewText(R.id.widget_title, context.getString(R.string.quota_widget_title))
        when (state) {
            is QuotaWidgetReadResult.Data -> {
                val summary = state.summary
                if (!summary.hasQuotaData) {
                    bindSmallNoData(context, views, summary.errorLabel)
                    return
                }
                views.setTextViewText(
                    R.id.five_hour_value,
                    context.getString(
                        R.string.quota_widget_small_five_hour,
                        formatRatio(summary.fiveHourRemainingRatio),
                    ),
                )
                views.setTextViewText(
                    R.id.weekly_value,
                    context.getString(
                        R.string.quota_widget_small_weekly,
                        formatRatio(summary.weeklyRemainingRatio),
                    ),
                )
                views.setTextViewText(
                    R.id.last_updated,
                    if (summary.isEffectivelyStale()) {
                        context.getString(R.string.quota_widget_stale_open_app)
                    } else {
                        formatUpdated(context, summary.lastUpdatedAt ?: summary.exportedAt)
                    },
                )
                bindStatusBadge(views, summary)
            }
            QuotaWidgetReadResult.NoData -> bindSmallNoData(context, views, null)
            QuotaWidgetReadResult.Error -> bindSmallNoData(
                context,
                views,
                context.getString(R.string.quota_widget_error),
            )
        }
    }

    private fun bindSmallNoData(
        context: Context,
        views: RemoteViews,
        errorLabel: String?,
    ) {
        views.setTextViewText(
            R.id.five_hour_value,
            errorLabel ?: context.getString(R.string.quota_widget_no_data),
        )
        views.setTextViewText(R.id.weekly_value, context.getString(R.string.quota_widget_open_app))
        views.setTextViewText(R.id.last_updated, context.getString(R.string.quota_widget_updated_none))
        views.setViewVisibility(R.id.stale_badge, View.GONE)
    }

    private fun bindMedium(
        context: Context,
        views: RemoteViews,
        state: QuotaWidgetReadResult,
    ) {
        views.setTextViewText(R.id.widget_title, context.getString(R.string.quota_widget_title))
        when (state) {
            is QuotaWidgetReadResult.Data -> {
                val summary = state.summary
                if (!summary.hasQuotaData) {
                    bindMediumNoData(context, views, summary.errorLabel)
                    return
                }
                views.setTextViewText(R.id.five_hour_value, formatRatio(summary.fiveHourRemainingRatio))
                views.setTextViewText(R.id.five_hour_reset, formatReset(context, summary.fiveHourResetAt))
                views.setTextViewText(R.id.weekly_value, formatRatio(summary.weeklyRemainingRatio))
                views.setTextViewText(R.id.weekly_reset, formatReset(context, summary.weeklyResetAt))
                val credits = summary.creditsRemaining
                if (credits == null) {
                    views.setViewVisibility(R.id.credits_value, View.GONE)
                } else {
                    views.setViewVisibility(R.id.credits_value, View.VISIBLE)
                    views.setTextViewText(
                        R.id.credits_value,
                        context.getString(R.string.quota_widget_credits, formatCredits(credits)),
                    )
                }
                views.setTextViewText(
                    R.id.source_confidence,
                    if (summary.isEffectivelyStale()) {
                        context.getString(R.string.quota_widget_open_app)
                    } else {
                        context.getString(
                            R.string.quota_widget_source_confidence,
                            formatConfidence(summary.parserConfidence),
                            formatSource(summary.source),
                        )
                    },
                )
                views.setTextViewText(
                    R.id.last_updated,
                    formatUpdated(context, summary.lastUpdatedAt ?: summary.exportedAt),
                )
                bindStatusBadge(views, summary)
            }
            QuotaWidgetReadResult.NoData -> bindMediumNoData(context, views, null)
            QuotaWidgetReadResult.Error -> bindMediumNoData(
                context,
                views,
                context.getString(R.string.quota_widget_error),
            )
        }
    }

    private fun bindMediumNoData(
        context: Context,
        views: RemoteViews,
        errorLabel: String?,
    ) {
        views.setTextViewText(R.id.five_hour_value, errorLabel ?: context.getString(R.string.quota_widget_no_data))
        views.setTextViewText(R.id.five_hour_reset, context.getString(R.string.quota_widget_open_app))
        views.setTextViewText(R.id.weekly_value, context.getString(R.string.quota_widget_no_data_short))
        views.setTextViewText(R.id.weekly_reset, context.getString(R.string.quota_widget_updated_none))
        views.setViewVisibility(R.id.credits_value, View.GONE)
        views.setTextViewText(R.id.source_confidence, context.getString(R.string.quota_widget_summary_only))
        views.setTextViewText(R.id.last_updated, context.getString(R.string.quota_widget_updated_none))
        views.setViewVisibility(R.id.stale_badge, View.GONE)
    }

    private fun bindStatusBadge(views: RemoteViews, summary: QuotaWidgetSummary) {
        val status = summary.statusLabel?.uppercase(Locale.US)
        val label = when {
            summary.isEffectivelyStale() -> "Stale"
            status == "LOW" -> "Low"
            status == "OK" -> "OK"
            !summary.errorLabel.isNullOrBlank() -> summary.errorLabel
            else -> null
        }
        if (label == null) {
            views.setViewVisibility(R.id.stale_badge, View.GONE)
        } else {
            views.setViewVisibility(R.id.stale_badge, View.VISIBLE)
            views.setTextViewText(R.id.stale_badge, label)
        }
    }

    private fun QuotaWidgetSummary.isEffectivelyStale(): Boolean {
        if (isStale) {
            return true
        }
        val updatedAt = lastUpdatedAt ?: exportedAt ?: return false
        return Duration.between(updatedAt, Instant.now()).toMinutes() > STALE_AFTER_MINUTES
    }

    private fun formatRatio(value: Double?): String {
        if (value == null) {
            return "--%"
        }
        return "${(value.coerceIn(0.0, 1.0) * 100).roundToInt()}%"
    }

    private fun formatReset(context: Context, value: Instant?): String {
        if (value == null) {
            return context.getString(R.string.quota_widget_reset_unknown)
        }
        return context.getString(R.string.quota_widget_reset_at, formatTime(value))
    }

    private fun formatUpdated(context: Context, value: Instant?): String {
        if (value == null) {
            return context.getString(R.string.quota_widget_updated_none)
        }
        return context.getString(R.string.quota_widget_updated_at, formatTime(value))
    }

    private fun formatTime(value: Instant): String {
        return DateTimeFormatter.ofPattern("HH:mm")
            .withZone(ZoneId.systemDefault())
            .format(value)
    }

    private fun formatCredits(value: Double): String {
        val rounded = if (value % 1.0 == 0.0) {
            value.toLong().toString()
        } else {
            String.format(Locale.US, "%.1f", value)
        }
        return rounded
    }

    private fun formatSource(value: String): String {
        return when (value) {
            "webViewManualExtraction" -> "Web"
            "localStorage" -> "Local"
            "mock" -> "Mock"
            else -> "Unknown"
        }
    }

    private fun formatConfidence(value: String): String {
        return when (value.lowercase(Locale.US)) {
            "high" -> "High"
            "medium" -> "Medium"
            "low" -> "Low"
            else -> "Unknown"
        }
    }

    fun openAppIntent(
        context: Context,
        target: String,
        action: String,
    ): Intent {
        return Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(QuotaWidgetConstants.EXTRA_SOURCE, QuotaWidgetConstants.SOURCE_WIDGET)
            putExtra(QuotaWidgetConstants.EXTRA_TARGET, target)
            putExtra(QuotaWidgetConstants.EXTRA_OPEN_ROUTE, target)
            putExtra(QuotaWidgetConstants.EXTRA_ACTION, action)
        }
    }

    private fun openAppPendingIntent(
        context: Context,
        target: String,
        action: String,
        requestCode: Int,
    ): PendingIntent {
        val intent = openAppIntent(context, target, action)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }
}
