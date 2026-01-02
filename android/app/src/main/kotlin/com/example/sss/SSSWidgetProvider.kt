package com.example.sss

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/**
 * Quick Search Widget Provider
 * Small widget for quick access to search and scan
 */
class SSSQuickSearchWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateQuickSearchWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onEnabled(context: Context) {
        // Widget is placed for the first time
    }
    
    override fun onDisabled(context: Context) {
        // Last widget removed
    }
    
    companion object {
        fun updateQuickSearchWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("home_widget", Context.MODE_PRIVATE)
            val containerCount = prefs.getInt("containerCount", 0)
            val itemCount = prefs.getInt("itemCount", 0)
            
            val views = RemoteViews(context.packageName, R.layout.widget_quick_search)
            
            // Update counts
            views.setTextViewText(R.id.container_count, "$containerCount")
            views.setTextViewText(R.id.item_count, "$itemCount")
            
            // Set up click intent to open search
            val searchIntent = Intent(Intent.ACTION_VIEW, Uri.parse("sss://search"))
            searchIntent.setPackage(context.packageName)
            val searchPendingIntent = PendingIntent.getActivity(
                context, 0, searchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, searchPendingIntent)
            
            // Set up QR scan intent
            val qrIntent = Intent(Intent.ACTION_VIEW, Uri.parse("sss://scan/qr"))
            qrIntent.setPackage(context.packageName)
            val qrPendingIntent = PendingIntent.getActivity(
                context, 1, qrIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.qr_button, qrPendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

/**
 * Recent Containers Widget Provider
 * Medium widget showing recent containers
 */
class SSSRecentContainersWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateRecentContainersWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    companion object {
        fun updateRecentContainersWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("home_widget", Context.MODE_PRIVATE)
            val containersJson = prefs.getString("recentContainers", "[]") ?: "[]"
            
            val views = RemoteViews(context.packageName, R.layout.widget_recent_containers)
            
            try {
                val containers = JSONArray(containersJson)
                
                // Update up to 3 container slots
                val containerViews = listOf(
                    Triple(R.id.container1_layout, R.id.container1_name, R.id.container1_count),
                    Triple(R.id.container2_layout, R.id.container2_name, R.id.container2_count),
                    Triple(R.id.container3_layout, R.id.container3_name, R.id.container3_count)
                )
                
                for (i in 0 until 3) {
                    val (layoutId, nameId, countId) = containerViews[i]
                    
                    if (i < containers.length()) {
                        val container = containers.getJSONObject(i)
                        val name = container.getString("name")
                        val itemCount = container.getInt("itemCount")
                        val deepLink = container.getString("deepLink")
                        
                        views.setTextViewText(nameId, name)
                        views.setTextViewText(countId, "$itemCount items")
                        views.setViewVisibility(layoutId, android.view.View.VISIBLE)
                        
                        // Set up click intent
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink))
                        intent.setPackage(context.packageName)
                        val pendingIntent = PendingIntent.getActivity(
                            context, i + 10, intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(layoutId, pendingIntent)
                    } else {
                        views.setViewVisibility(layoutId, android.view.View.GONE)
                    }
                }
            } catch (e: Exception) {
                // Handle JSON parsing error
            }
            
            // Set up header click to open containers list
            val listIntent = Intent(Intent.ACTION_VIEW, Uri.parse("sss://containers"))
            listIntent.setPackage(context.packageName)
            val listPendingIntent = PendingIntent.getActivity(
                context, 100, listIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_header, listPendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

/**
 * Stats Widget Provider
 * Large widget showing storage statistics
 */
class SSSStatsWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateStatsWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    companion object {
        fun updateStatsWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("home_widget", Context.MODE_PRIVATE)
            
            val totalContainers = prefs.getInt("totalContainers", 0)
            val totalItems = prefs.getInt("totalItems", 0)
            val boxCount = prefs.getInt("boxCount", 0)
            val bagCount = prefs.getInt("bagCount", 0)
            val drawerCount = prefs.getInt("drawerCount", 0)
            
            val views = RemoteViews(context.packageName, R.layout.widget_stats)
            
            views.setTextViewText(R.id.total_containers, "$totalContainers")
            views.setTextViewText(R.id.total_items, "$totalItems")
            views.setTextViewText(R.id.box_count, "$boxCount boxes")
            views.setTextViewText(R.id.bag_count, "$bagCount bags")
            views.setTextViewText(R.id.drawer_count, "$drawerCount drawers")
            
            // Set up click intent to open app
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("sss://stats"))
            intent.setPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context, 200, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
