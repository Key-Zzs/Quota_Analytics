package com.keyzzs.quota_analytics.widget

import android.content.Context

sealed class QuotaWidgetReadResult {
    data class Data(val summary: QuotaWidgetSummary) : QuotaWidgetReadResult()
    object NoData : QuotaWidgetReadResult()
    object Error : QuotaWidgetReadResult()
}

class QuotaWidgetSummaryReader(private val context: Context) {
    fun read(): QuotaWidgetReadResult {
        val raw = context.getSharedPreferences(
            QuotaWidgetConstants.PREFERENCES_NAME,
            Context.MODE_PRIVATE,
        ).getString(QuotaWidgetConstants.LATEST_SUMMARY_JSON_KEY, null)

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
