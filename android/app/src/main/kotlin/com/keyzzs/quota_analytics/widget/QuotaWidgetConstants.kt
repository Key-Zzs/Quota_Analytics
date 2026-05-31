package com.keyzzs.quota_analytics.widget

object QuotaWidgetConstants {
    const val CHANNEL_NAME = "quota_analytics/widget"

    const val METHOD_SAVE_SUMMARY = "saveQuotaWidgetSummary"
    const val METHOD_CLEAR_SUMMARY = "clearQuotaWidgetSummary"
    const val METHOD_UPDATE_WIDGETS = "updateQuotaWidgets"
    const val METHOD_GET_STATUS = "getQuotaWidgetStatus"
    const val METHOD_CONSUME_WIDGET_LAUNCH_ACTION = "consumeWidgetLaunchAction"
    const val METHOD_WIDGET_LAUNCH_ACTION = "widgetLaunchAction"

    const val PREFERENCES_NAME = "quota_widget_summary"
    const val LATEST_SUMMARY_JSON_KEY = "latest_summary_json"
    const val FLUTTER_PREFERENCES_NAME = "FlutterSharedPreferences"
    const val FLUTTER_LATEST_SUMMARY_JSON_KEY = "flutter.widget.latest_summary_json"

    const val ACTION_UPDATE_QUOTA_WIDGETS =
        "com.keyzzs.quota_analytics.widget.ACTION_UPDATE_QUOTA_WIDGETS"
    const val ACTION_WIDGET_OPEN_REFRESH_FLOW =
        "com.keyzzs.quota_analytics.widget.ACTION_OPEN_REFRESH_FLOW"

    const val EXTRA_OPEN_ROUTE = "open_route"
    const val EXTRA_SOURCE = "source"
    const val EXTRA_TARGET = "target"
    const val EXTRA_ACTION = "action"
    const val OPEN_ROUTE_QUOTA = "quota"
    const val TARGET_QUOTA = "quota"
    const val TARGET_REFRESH_USAGE_PAGE = "refreshUsagePage"
    const val SOURCE_WIDGET = "widget"
    const val ACTION_OPEN_QUOTA = "openQuota"
    const val ACTION_OPEN_REFRESH_FLOW = "openRefreshFlow"
}
