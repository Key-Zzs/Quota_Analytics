package com.keyzzs.quota_analytics.widget

object QuotaWidgetConstants {
    const val CHANNEL_NAME = "quota_analytics/android_widget"

    const val METHOD_SAVE_SUMMARY = "saveQuotaWidgetSummary"
    const val METHOD_CLEAR_SUMMARY = "clearQuotaWidgetSummary"
    const val METHOD_UPDATE_WIDGETS = "updateQuotaWidgets"
    const val METHOD_GET_STATUS = "getQuotaWidgetStatus"

    const val PREFERENCES_NAME = "quota_widget_summary"
    const val LATEST_SUMMARY_JSON_KEY = "latest_summary_json"

    const val EXTRA_OPEN_ROUTE = "open_route"
    const val EXTRA_SOURCE = "source"
    const val OPEN_ROUTE_QUOTA = "quota"
    const val SOURCE_WIDGET = "widget"
}
