package com.ferdidrgn.azgame.wear

internal data class WearRoom(
    val gameName: String = "AZOyun",
    val roomCode: String = "",
    val status: String = "unknown",
    val playerCount: Int = 0,
    val maxPlayers: Int = 0,
    val eventId: String = "",
    val eventType: String = "",
    val publishedAt: Long = 0L,
) {
    val stale: Boolean
        get() = publishedAt == 0L || System.currentTimeMillis() - publishedAt > 120_000L
}
