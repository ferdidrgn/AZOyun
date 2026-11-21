package com.ferdidrgn.azgame.wear

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScalingLazyColumn
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.TimeText
import androidx.wear.compose.material3.rememberScalingLazyListState
import androidx.wear.remote.interactions.RemoteActivityHelper
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable

class WearHomeActivity : ComponentActivity(), DataClient.OnDataChangedListener {
    private var room by mutableStateOf(WearRoom())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        room = readWearRoom()
        setContent {
            MaterialTheme {
                val listState = rememberScalingLazyListState()
                ScreenScaffold(timeText = { TimeText() }) { contentPadding ->
                    ScalingLazyColumn(state = listState, contentPadding = contentPadding) {
                        item { Text("AZOyun", style = MaterialTheme.typography.titleSmall) }
                        item {
                            Text(
                                if (room.roomCode.isBlank()) "Etkin oda yok" else room.gameName,
                                style = MaterialTheme.typography.titleMedium,
                            )
                        }
                        item {
                            Text(if (room.roomCode.isBlank()) "Oda bekleniyor" else "Kod: ${room.roomCode}")
                        }
                        if (room.roomCode.isNotBlank()) {
                            item {
                                val capacity = if (room.maxPlayers > 0) "/${room.maxPlayers}" else ""
                                Text("Oyuncu: ${room.playerCount}$capacity")
                            }
                        }
                        item {
                            Text(
                                if (room.stale) "Güncel değil · telefonu aç"
                                else statusLabel(room.status),
                            )
                        }
                        item { Button(onClick = ::openPhone) { Text("Telefonu aç") } }
                    }
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        Wearable.getDataClient(this).addListener(this)
    }

    override fun onStop() {
        Wearable.getDataClient(this).removeListener(this)
        super.onStop()
    }

    override fun onDataChanged(events: DataEventBuffer) {
        events.forEach { event ->
            if (event.type != DataClient.EVENT_TYPE_CHANGED ||
                event.dataItem.uri.path != "/azoyun/room/summary"
            ) return@forEach
            room = readWearRoom(DataMapItem.fromDataItem(event.dataItem).dataMap)
        }
    }

    private fun readWearRoom(data: com.google.android.gms.wearable.DataMap? = null): WearRoom {
        if (data != null) {
            return WearRoom(
                gameName = data.getString("gameName", "AZOyun"),
                roomCode = data.getString("roomCode", ""),
                status = data.getString("status", "unknown"),
                playerCount = data.getInt("playerCount", 0),
                maxPlayers = data.getInt("maxPlayers", 0),
                eventId = data.getString("eventId", ""),
                eventType = data.getString("eventType", ""),
                publishedAt = data.getLong("publishedAt", 0L),
            )
        }
        val prefs = getSharedPreferences("wear-room", Context.MODE_PRIVATE)
        return WearRoom(
            gameName = prefs.getString("gameName", "AZOyun") ?: "AZOyun",
            roomCode = prefs.getString("roomCode", "") ?: "",
            status = prefs.getString("status", "unknown") ?: "unknown",
            playerCount = prefs.getInt("playerCount", 0),
            maxPlayers = prefs.getInt("maxPlayers", 0),
            eventId = prefs.getString("eventId", "") ?: "",
            eventType = prefs.getString("eventType", "") ?: "",
            publishedAt = prefs.getLong("publishedAt", 0L),
        )
    }

    private fun openPhone() {
        val intent = Intent(Intent.ACTION_VIEW)
            .setData(Uri.parse("azoyun://open"))
            .addCategory(Intent.CATEGORY_BROWSABLE)
        RemoteActivityHelper(this, mainExecutor).startRemoteActivity(intent)
    }
}

class WearRoomListenerService : com.google.android.gms.wearable.WearableListenerService() {
    override fun onDataChanged(events: DataEventBuffer) {
        events.forEach { event ->
            if (event.type != DataClient.EVENT_TYPE_CHANGED ||
                event.dataItem.uri.path != "/azoyun/room/summary"
            ) return@forEach
            val map = DataMapItem.fromDataItem(event.dataItem).dataMap
            val prefs = getSharedPreferences("wear-room", Context.MODE_PRIVATE)
            val previousEventId = prefs.getString("eventId", null)
            val eventId = map.getString("eventId", "")
            val eventType = map.getString("eventType", "")
            val publishedAt = map.getLong("publishedAt", 0L)
            prefs.edit()
                .putString("gameName", map.getString("gameName", "AZOyun"))
                .putString("roomCode", map.getString("roomCode", ""))
                .putString("status", map.getString("status", "unknown"))
                .putInt("playerCount", map.getInt("playerCount", 0))
                .putInt("maxPlayers", map.getInt("maxPlayers", 0))
                .putString("eventId", eventId)
                .putString("eventType", eventType)
                .putLong("publishedAt", publishedAt)
                .apply()
            val now = System.currentTimeMillis()
            val recent = publishedAt in (now - 120_000L)..(now + 30_000L)
            val hapticEvent = eventType in setOf(
                "playerJoined", "roomStarted", "turnChanged", "roomFinished",
            )
            if (recent && hapticEvent && eventId.isNotBlank() && eventId != previousEventId) {
                getSystemService(Vibrator::class.java)?.vibrate(
                    VibrationEffect.createOneShot(90, VibrationEffect.DEFAULT_AMPLITUDE),
                )
            }
        }
    }
}

private fun statusLabel(status: String): String = when (status) {
    "waiting" -> "Oyuncular bekleniyor"
    "playing" -> "Oyun sürüyor"
    "finished" -> "Maç tamamlandı"
    else -> "Durum bilinmiyor"
}
