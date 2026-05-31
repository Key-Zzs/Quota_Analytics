package com.keyzzs.quota_analytics.widget

import android.content.Context

sealed class QuotaWidgetReadResult {
    data class Data(val summary: QuotaWidgetSummary) : QuotaWidgetReadResult()
    object NoData : QuotaWidgetReadResult()
    object Error : QuotaWidgetReadResult()
}

class QuotaWidgetSummaryReader(private val context: Context) {
    fun read(): QuotaWidgetReadResult {
        val nativeRaw = context.getSharedPreferences(
            QuotaWidgetConstants.PREFERENCES_NAME,
            Context.MODE_PRIVATE,
        ).getString(QuotaWidgetConstants.LATEST_SUMMARY_JSON_KEY, null)
        val raw = nativeRaw ?: context.getSharedPreferences(
            QuotaWidgetConstants.FLUTTER_PREFERENCES_NAME,
            Context.MODE_PRIVATE,
        ).getString(QuotaWidgetConstants.FLUTTER_LATEST_SUMMARY_JSON_KEY, null)

        if (raw.isNullOrBlank()) {
            return QuotaWidgetReadResult.NoData
        }

        return runCatching {
            QuotaWidgetReadResult.Data(QuotaWidgetSummary.fromJson(raw))
        }.getOrElse {
            QuotaWidgetReadResult.Error
        }
    }
}
