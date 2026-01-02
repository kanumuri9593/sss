package com.example.sss

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

/**
 * Handler for Google Assistant App Actions and Gemini integration
 */
class AssistantActionHandler(private val context: Context) {
    
    companion object {
        private const val CHANNEL = "com.example.sss/assistant"
        private const val MAX_SHORTCUTS = 4
    }
    
    private var methodChannel: MethodChannel? = null
    
    /**
     * Set up the method channel for Flutter communication
     */
    fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateShortcuts" -> {
                    val shortcuts = call.argument<List<Map<String, Any>>>("shortcuts")
                    if (shortcuts != null) {
                        updateDynamicShortcuts(shortcuts)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Shortcuts list is null", null)
                    }
                }
                "reportShortcutUsed" -> {
                    val shortcutId = call.argument<String>("shortcutId")
                    if (shortcutId != null) {
                        ShortcutManagerCompat.reportShortcutUsed(context, shortcutId)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Shortcut ID is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    /**
     * Update dynamic shortcuts for App Actions
     */
    private fun updateDynamicShortcuts(shortcuts: List<Map<String, Any>>) {
        // Remove existing dynamic shortcuts
        ShortcutManagerCompat.removeAllDynamicShortcuts(context)
        
        val shortcutInfoList = shortcuts.take(MAX_SHORTCUTS).mapNotNull { shortcut ->
            try {
                val id = shortcut["id"] as? String ?: return@mapNotNull null
                val shortLabel = shortcut["shortLabel"] as? String ?: return@mapNotNull null
                val longLabel = shortcut["longLabel"] as? String ?: shortLabel
                val iconType = shortcut["iconType"] as? String ?: "box"
                val deepLink = shortcut["deepLink"] as? String ?: return@mapNotNull null
                
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
                    setPackage(context.packageName)
                }
                
                val iconRes = when (iconType) {
                    "box" -> R.drawable.ic_box
                    "bag" -> R.drawable.ic_bag
                    "drawer" -> R.drawable.ic_drawer
                    else -> R.drawable.ic_box
                }
                
                ShortcutInfoCompat.Builder(context, id)
                    .setShortLabel(shortLabel)
                    .setLongLabel(longLabel)
                    .setIcon(IconCompat.createWithResource(context, iconRes))
                    .setIntent(intent)
                    .setCategories(setOf("com.example.sss.OPEN_CONTAINER"))
                    .build()
            } catch (e: Exception) {
                null
            }
        }
        
        if (shortcutInfoList.isNotEmpty()) {
            ShortcutManagerCompat.addDynamicShortcuts(context, shortcutInfoList)
        }
    }
    
    /**
     * Handle incoming intent from Google Assistant
     */
    fun handleAssistantIntent(intent: Intent): Boolean {
        val action = intent.action ?: return false
        
        return when {
            action == "android.intent.action.VIEW" -> {
                // Handle deep link from Assistant
                val data = intent.data
                if (data != null && data.scheme == "sss") {
                    // Let Flutter handle the deep link
                    true
                } else {
                    false
                }
            }
            action == "actions.intent.OPEN_APP_FEATURE" -> {
                // Handle built-in intent for opening app feature
                val feature = intent.getStringExtra("feature")
                handleOpenFeature(feature)
                true
            }
            action == "actions.intent.GET_THING" -> {
                // Handle search/get thing intent
                val query = intent.getStringExtra("thing.name")
                if (query != null) {
                    methodChannel?.invokeMethod("searchContainers", mapOf("query" to query))
                }
                true
            }
            else -> false
        }
    }
    
    private fun handleOpenFeature(feature: String?) {
        when (feature) {
            "search" -> methodChannel?.invokeMethod("searchContainers", null)
            "scan_qr" -> methodChannel?.invokeMethod("scanQR", null)
            "scan_nfc" -> methodChannel?.invokeMethod("scanNFC", null)
            "stats" -> methodChannel?.invokeMethod("getStats", null)
            else -> methodChannel?.invokeMethod("searchContainers", null)
        }
    }
}
