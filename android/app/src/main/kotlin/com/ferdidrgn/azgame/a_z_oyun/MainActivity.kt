package com.ferdidrgn.azgame

import android.os.Bundle
import com.google.android.gms.games.PlayGamesSdk
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Play Games Services v2 (bkz. ROADMAP 8.7) — Google'ın resmi kurulum
        // adımı gereği super.onCreate()'den önce çağrılmalı.
        PlayGamesSdk.initialize(this)
        super.onCreate(savedInstanceState)
    }
}
