package com.example.spotnitj

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.net.URL

class SeatWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val REFRESH_ACTION =
            "com.example.spotnitj.REFRESH"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {

        for (appWidgetId in appWidgetIds) {

            val views = RemoteViews(
                context.packageName,
                R.layout.seat_widget
            )

            val seats =
                widgetData.getInt("seats", 0)

            val details =
                widgetData.getString(
                    "details",
                    "NO DATA"
                ) ?: "NO DATA"

            val dots =
                widgetData.getString(
                    "dots",
                    "○ ○ ○ ○ ○ ○ ○ ○ ○ ○"
                ) ?: "○ ○ ○ ○ ○ ○ ○ ○ ○ ○"

            val level =
                widgetData.getString(
                    "level",
                    "GREEN"
                ) ?: "GREEN"

            views.setTextViewText(
                R.id.seats,
                if (seats <= 0)
                    "NO SEATS"
                else
                    "$seats SEATS"
            )

            views.setTextViewText(
                R.id.details,
                details
            )

            views.setTextViewText(
                R.id.progressDots,
                dots
            )

            val color = when (level) {

                "GREEN" ->
                    Color.parseColor("#00FF99")

                "YELLOW" ->
                    Color.parseColor("#FFD500")

                else ->
                    Color.parseColor("#FF3B30")
            }

            views.setTextColor(
                R.id.progressDots,
                color
            )

            val refreshIntent = Intent(
                context,
                SeatWidgetProvider::class.java
            ).apply {
                action = REFRESH_ACTION
            }

            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    0,
                    refreshIntent,
                    PendingIntent.FLAG_IMMUTABLE or
                            PendingIntent.FLAG_UPDATE_CURRENT
                )

            views.setOnClickPendingIntent(
                R.id.refresh,
                pendingIntent
            )

            appWidgetManager.updateAppWidget(
                appWidgetId,
                views
            )
        }
    }

    override fun onReceive(
        context: Context,
        intent: Intent
    ) {

        super.onReceive(context, intent)

        if (intent.action == REFRESH_ACTION) {

            CoroutineScope(Dispatchers.IO).launch {

                val manager =
                    AppWidgetManager.getInstance(context)

                val ids =
                    manager.getAppWidgetIds(
                        ComponentName(
                            context,
                            SeatWidgetProvider::class.java
                        )
                    )

                val loadingViews =
                    RemoteViews(
                        context.packageName,
                        R.layout.seat_widget
                    )

                loadingViews.setTextViewText(
                    R.id.refresh,
                    "⋯"
                )

                for (id in ids) {

                    manager.partiallyUpdateAppWidget(
                        id,
                        loadingViews
                    )
                }

                try {

                    val response =
                        URL(
                            "https://api.opensourcenitj.com/library/getSeats"
                        ).readText()

                    val json =
                        JSONObject(response)

                    val seats =
                        json.getInt("totalAvailableSeats")

                    val capacity =
                        json.getInt("totalCapacity")

                    val occupied =
                        capacity - seats

                    val percent =
                        ((occupied.toFloat() /
                                capacity.toFloat()) * 100).toInt()

                    val dotsFilled =
                        percent / 10

                    val dots =
                        buildString {

                            for (i in 0 until 10) {

                                append(
                                    if (i < dotsFilled)
                                        "● "
                                    else
                                        "○ "
                                )
                            }
                        }

                    val level = when {

                        percent <= 50 ->
                            "GREEN"

                        percent <= 75 ->
                            "YELLOW"

                        else ->
                            "RED"
                    }

                    val floors =
                        json.getJSONArray("capacity")

                    val details =
                        buildString {

                            for (i in 0 until floors.length()) {

                                val floor =
                                    floors.getJSONObject(i)

                                val available =
                                    floor.getInt(
                                        "availableSeats"
                                    )

                                if (available > 0) {

                                    val name =
                                        floor.getString("floor")
                                            .replace(
                                                "Ground Floor",
                                                "GROUND"
                                            )
                                            .replace(
                                                "Floor ",
                                                ""
                                            )

                                    append(
                                        "$available IN $name\n"
                                    )
                                }
                            }
                        }

                    val prefs =
                        context.getSharedPreferences(
                            "HomeWidgetPreferences",
                            Context.MODE_PRIVATE
                        )

                    prefs.edit()
                        .putInt("seats", seats)
                        .putString("details", details)
                        .putString("dots", dots)
                        .putString("level", level)
                        .apply()

                    onUpdate(
                        context,
                        manager,
                        ids,
                        prefs
                    )

                    val finalViews =
                        RemoteViews(
                            context.packageName,
                            R.layout.seat_widget
                        )

                    finalViews.setTextViewText(
                        R.id.refresh,
                        "↻"
                    )

                    for (id in ids) {

                        manager.partiallyUpdateAppWidget(
                            id,
                            finalViews
                        )
                    }

                } catch (e: Exception) {

                    e.printStackTrace()
                }
            }
        }
    }
}