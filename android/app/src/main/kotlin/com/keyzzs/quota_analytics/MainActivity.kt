package com.keyzzs.quota_analytics

import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.keyzzs.quota_analytics.widget.QuotaWidgetConstants
import com.keyzzs.quota_analytics.widget.QuotaWidgetSummary
import com.keyzzs.quota_analytics.widget.QuotaWidgetUpdater
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null
    private var pendingWidgetLaunchAction: Map<String, String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingWidgetLaunchAction = widgetLaunchActionFromIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QuotaWidgetConstants.CHANNEL_NAME,
        )
        widgetChannel?.setMethodCallHandler { call, result ->
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

                QuotaWidgetConstants.METHOD_CONSUME_WIDGET_LAUNCH_ACTION -> {
                    val action = pendingWidgetLaunchAction
                    pendingWidgetLaunchAction = null
                    result.success(action)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = widgetLaunchActionFromIntent(intent) ?: return
        pendingWidgetLaunchAction = action
        widgetChannel?.invokeMethod(
            QuotaWidgetConstants.METHOD_WIDGET_LAUNCH_ACTION,
            action,
        )
    }

    private fun widgetLaunchActionFromIntent(intent: Intent?): Map<String, String>? {
        if (intent == null) {
            return null
        }
        val source = intent.getStringExtra(QuotaWidgetConstants.EXTRA_SOURCE)
        if (source != QuotaWidgetConstants.SOURCE_WIDGET) {
            return null
        }
        val target = intent.getStringExtra(QuotaWidgetConstants.EXTRA_TARGET)
            ?: intent.getStringExtra(QuotaWidgetConstants.EXTRA_OPEN_ROUTE)
            ?: QuotaWidgetConstants.TARGET_QUOTA
        val safeTarget = when (target) {
            QuotaWidgetConstants.TARGET_REFRESH_USAGE_PAGE ->
                QuotaWidgetConstants.TARGET_REFRESH_USAGE_PAGE
            else -> QuotaWidgetConstants.TARGET_QUOTA
        }
        val action = intent.getStringExtra(QuotaWidgetConstants.EXTRA_ACTION)
            ?: if (safeTarget == QuotaWidgetConstants.TARGET_REFRESH_USAGE_PAGE) {
                QuotaWidgetConstants.ACTION_OPEN_REFRESH_FLOW
            } else {
                QuotaWidgetConstants.ACTION_OPEN_QUOTA
            }
        val safeAction = when (action) {
            QuotaWidgetConstants.ACTION_OPEN_REFRESH_FLOW ->
                QuotaWidgetConstants.ACTION_OPEN_REFRESH_FLOW
            QuotaWidgetConstants.ACTION_OPEN_QUOTA ->
                QuotaWidgetConstants.ACTION_OPEN_QUOTA
            else -> QuotaWidgetConstants.ACTION_OPEN_QUOTA
        }
        return mapOf(
            QuotaWidgetConstants.EXTRA_SOURCE to QuotaWidgetConstants.SOURCE_WIDGET,
            QuotaWidgetConstants.EXTRA_TARGET to safeTarget,
            QuotaWidgetConstants.EXTRA_ACTION to safeAction,
        )
    }
}
