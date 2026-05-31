package com.keyzzs.quota_analytics

import android.content.Context
import com.keyzzs.quota_analytics.widget.QuotaWidgetConstants
import com.keyzzs.quota_analytics.widget.QuotaWidgetSummary
import com.keyzzs.quota_analytics.widget.QuotaWidgetUpdater
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QuotaWidgetConstants.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                QuotaWidgetConstants.METHOD_SAVE_SUMMARY -> {
                    val summaryJson = call.argument<String>("summaryJson")
                    if (summaryJson.isNullOrBlank()) {
                        result.error(
                            "invalid_argument",
                            "summaryJson is required",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    runCatching {
                        val safeSummaryJson = QuotaWidgetSummary
                            .fromJson(summaryJson)
                            .toStorageJson()
                        getSharedPreferences(
                            QuotaWidgetConstants.PREFERENCES_NAME,
                            Context.MODE_PRIVATE,
                        ).edit()
                            .putString(
                                QuotaWidgetConstants.LATEST_SUMMARY_JSON_KEY,
                                safeSummaryJson,
                            )
                            .apply()
                    }.fold(
                        onSuccess = { result.success(null) },
                        onFailure = {
                            result.error(
                                "invalid_summary_json",
                                "Unable to store widget summary",
                                null,
                            )
                        },
                    )
                }

                QuotaWidgetConstants.METHOD_CLEAR_SUMMARY -> {
                    getSharedPreferences(
                        QuotaWidgetConstants.PREFERENCES_NAME,
                        Context.MODE_PRIVATE,
                    ).edit()
                        .remove(QuotaWidgetConstants.LATEST_SUMMARY_JSON_KEY)
                        .apply()
                    result.success(null)
                }

                QuotaWidgetConstants.METHOD_UPDATE_WIDGETS -> {
                    QuotaWidgetUpdater.updateAll(this)
                    result.success(null)
                }

                QuotaWidgetConstants.METHOD_GET_STATUS -> {
                    val installedWidgetCount = QuotaWidgetUpdater.installedWidgetCount(this)
                    result.success(
                        mapOf(
                            "available" to true,
                            "installedWidgetCount" to installedWidgetCount,
                            "hasInstalledWidgets" to (installedWidgetCount > 0),
                        ),
                    )
                }

                else -> result.notImplemented()
            }
        }
    }
}
