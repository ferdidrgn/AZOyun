package com.ferdidrgn.azgame

import android.os.Bundle
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.PlayGamesSdk
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

    private fun reportPlayGamesError(result: MethodChannel.Result, error: Exception?) {
        result.error("play_games_error", null, (error as? ApiException)?.statusCode)
    }
}
