package com.keyzzs.quota_analytics.widget

import org.json.JSONObject
import java.time.Instant

data class QuotaWidgetSummary(
    val schemaVersion: String,
    val id: String,
    val fiveHourRemainingRatio: Double?,
    val fiveHourResetText: String?,
    val fiveHourResetAt: Instant?,
    val weeklyRemainingRatio: Double?,
    val weeklyResetText: String?,
    val weeklyResetAt: Instant?,
    val creditsRemaining: Double?,
    val lastUpdatedAt: Instant?,
    val source: String,
    val parserConfidence: String,
    val isStale: Boolean,
    val staleReason: String,
    val displayTitle: String,
    val displaySubtitle: String,
    val statusLabel: String?,
    val errorLabel: String?,
    val exportedAt: Instant?,
) {
    val hasQuotaData: Boolean
        get() = fiveHourRemainingRatio != null ||
            weeklyRemainingRatio != null ||
            creditsRemaining != null

    fun toStorageJson(): String {
        return JSONObject()
            .put("schemaVersion", schemaVersion)
            .put("id", id)
            .putNullable("fiveHourRemainingRatio", fiveHourRemainingRatio)
            .putNullable("fiveHourResetText", fiveHourResetText)
            .putNullable("fiveHourResetAt", fiveHourResetAt?.toString())
            .putNullable("weeklyRemainingRatio", weeklyRemainingRatio)
            .putNullable("weeklyResetText", weeklyResetText)
            .putNullable("weeklyResetAt", weeklyResetAt?.toString())
            .putNullable("creditsRemaining", creditsRemaining)
            .putNullable("lastUpdatedAt", lastUpdatedAt?.toString())
            .put("source", source)
            .put("parserConfidence", parserConfidence)
            .put("isStale", isStale)
            .put("staleReason", staleReason)
            .put("displayTitle", displayTitle)
            .put("displaySubtitle", displaySubtitle)
            .putNullable("statusLabel", statusLabel)
            .putNullable("errorLabel", errorLabel)
            .putNullable("exportedAt", exportedAt?.toString())
            .toString()
    }

    companion object {
        fun fromJson(raw: String): QuotaWidgetSummary {
            return fromJsonObject(JSONObject(raw))
        }

        fun fromJsonObject(json: JSONObject): QuotaWidgetSummary {
            val exportedAt = readInstant(json, "exportedAt")
            return QuotaWidgetSummary(
                schemaVersion = readSafeString(json, "schemaVersion") ?: "1",
                id = readSafeString(json, "id") ?: "widget-summary-${exportedAt ?: "unknown"}",
                fiveHourRemainingRatio = readRatio(json, "fiveHourRemainingRatio"),
                fiveHourResetText = readSafeString(json, "fiveHourResetText"),
                fiveHourResetAt = readInstant(json, "fiveHourResetAt"),
                weeklyRemainingRatio = readRatio(json, "weeklyRemainingRatio"),
                weeklyResetText = readSafeString(json, "weeklyResetText"),
                weeklyResetAt = readInstant(json, "weeklyResetAt"),
                creditsRemaining = readDouble(json, "creditsRemaining"),
                lastUpdatedAt = readInstant(json, "lastUpdatedAt"),
                source = readSafeString(json, "source") ?: "unknown",
                parserConfidence = readSafeString(json, "parserConfidence") ?: "unknown",
                isStale = json.optBoolean("isStale", false),
                staleReason = readSafeString(json, "staleReason") ?: "unknown",
                displayTitle = readSafeString(json, "displayTitle") ?: "Quota Analytics",
                displaySubtitle = readSafeString(json, "displaySubtitle") ?: "No quota data",
                statusLabel = readSafeString(json, "statusLabel"),
                errorLabel = readSafeString(json, "errorLabel"),
                exportedAt = exportedAt,
            )
        }

        private fun readSafeString(json: JSONObject, key: String): String? {
            if (!json.has(key) || json.isNull(key)) {
                return null
            }
            val value = json.optString(key, "").trim()
            if (value.isEmpty()) {
                return null
            }
            val singleLine = value.replace(Regex("\\s+"), " ")
            return singleLine.take(96)
        }

        private fun readDouble(json: JSONObject, key: String): Double? {
            if (!json.has(key) || json.isNull(key)) {
                return null
            }
            val value = json.optDouble(key, Double.NaN)
            return if (value.isNaN()) null else value
        }

        private fun readRatio(json: JSONObject, key: String): Double? {
            return readDouble(json, key)?.coerceIn(0.0, 1.0)
        }

        private fun readInstant(json: JSONObject, key: String): Instant? {
            val value = readSafeString(json, key) ?: return null
            return runCatching { Instant.parse(value) }.getOrNull()
        }
    }
}

private fun JSONObject.putNullable(key: String, value: Any?): JSONObject {
    return if (value == null) {
        put(key, JSONObject.NULL)
    } else {
        put(key, value)
    }
}
