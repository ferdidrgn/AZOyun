package com.ferdidrgn.azgame

import android.os.Bundle
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.PlayGamesSdk
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Play Games Services v2 (bkz. ROADMAP 8.7) — Google'ın resmi kurulum
        // adımı gereği super.onCreate()'den önce çağrılmalı.
        PlayGamesSdk.initialize(this)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "azoyun/play_games")
            .setMethodCallHandler { call, result ->
                if (call.method == "player") {
                    loadPlayer(call.argument<Boolean>("interactive") == true, result)
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "azoyun/wear")
            .setMethodCallHandler { call, result ->
                if (call.method == "publishRoomSummary") {
                    val arguments = call.arguments as? Map<*, *>
                    if (arguments == null) {
                        result.error("invalid_summary", "Room summary is missing", null)
                    } else {
                        publishWearRoomSummary(arguments, result)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun loadPlayer(interactive: Boolean, result: MethodChannel.Result) {
        val availability = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(this)
        if (availability != ConnectionResult.SUCCESS) {
            result.error("services_unavailable", null, availability)
            return
        }

        val client = PlayGames.getGamesSignInClient(this)
        val authentication = if (interactive) client.signIn() else client.isAuthenticated
        authentication.addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                reportPlayGamesError(result, task.exception)
            } else if (!task.result.isAuthenticated) {
                result.success(null)
            } else {
                PlayGames.getPlayersClient(this).currentPlayer.addOnCompleteListener { playerTask ->
                    if (playerTask.isSuccessful) {
                        val player = playerTask.result
                        result.success(mapOf("id" to player.playerId, "name" to player.displayName))
                    } else {
                        reportPlayGamesError(result, playerTask.exception)
                    }
                }
            }
        }
    }

    private fun publishWearRoomSummary(
        arguments: Map<*, *>,
        result: MethodChannel.Result,
    ) {
        val availability = GoogleApiAvailability.getInstance()
            .isGooglePlayServicesAvailable(this)
        if (availability != ConnectionResult.SUCCESS) {
            result.success(false)
            return
        }

        val safeString = { key: String, maxLength: Int ->
            (arguments[key] as? String)?.trim()?.take(maxLength).orEmpty()
        }
        val roomKey = safeString("roomKey", 180)
        val gameName = safeString("gameName", 48)
        val roomCode = safeString("roomCode", 12)
        val status = safeString("status", 16)
        val eventType = safeString("eventType", 24)
        val allowedStatuses = setOf("waiting", "playing", "finished", "unknown")
        val allowedEvents = setOf(
            "roomSnapshot", "playerJoined", "roomStarted", "turnChanged", "roomFinished", "roomUpdated"
        )
        if (roomKey.isEmpty() || gameName.isEmpty() ||
            status !in allowedStatuses || eventType !in allowedEvents
        ) {
            result.error("invalid_summary", "Room summary fields are invalid", null)
            return
        }

        Wearable.getCapabilityClient(this)
            .getCapability("azoyun_wear_app", CapabilityClient.FILTER_REACHABLE)
            .addOnSuccessListener { capability ->
                if (capability.nodes.isEmpty()) {
                    result.success(false)
                    return@addOnSuccessListener
                }

                val data = PutDataMapRequest.create("/azoyun/room/summary").apply {
                    dataMap.putInt("schemaVersion", 1)
                    dataMap.putString("roomKey", roomKey)
                    dataMap.putString("gameName", gameName)
                    dataMap.putString("roomCode", roomCode)
                    dataMap.putString("status", status)
                    dataMap.putInt("playerCount", (arguments["playerCount"] as? Number)
                        ?.toInt()?.coerceIn(0, 64) ?: 0)
                    dataMap.putInt("maxPlayers", (arguments["maxPlayers"] as? Number)
                        ?.toInt()?.coerceIn(0, 64) ?: 0)
                    dataMap.putInt("revision", (arguments["revision"] as? Number)
                        ?.toInt()?.coerceAtLeast(0) ?: 0)
                    dataMap.putString("eventType", eventType)
                    dataMap.putString("eventId", safeString("eventId", 220))
                    dataMap.putLong("publishedAt", (arguments["publishedAt"] as? Number)?.toLong() ?: System.currentTimeMillis())
                }.asPutDataRequest().setUrgent()

                Wearable.getDataClient(this).putDataItem(data)
                    .addOnSuccessListener { result.success(true) }
                    .addOnFailureListener { result.success(false) }
            }
            .addOnFailureListener { result.success(false) }
    }

    private fun reportPlayGamesError(result: MethodChannel.Result, error: Exception?) {
        result.error("play_games_error", null, (error as? ApiException)?.statusCode)
    }
}
