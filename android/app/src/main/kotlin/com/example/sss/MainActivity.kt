package com.example.sss

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var assistantHandler: AssistantActionHandler
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up Assistant action handler
        assistantHandler = AssistantActionHandler(this)
        assistantHandler.setupMethodChannel(flutterEngine)
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle intent if launched from Assistant or widget
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        
        // Try to handle as Assistant intent
        if (::assistantHandler.isInitialized) {
            assistantHandler.handleAssistantIntent(intent)
        }
    }
}
