package com.animind.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Purple = Color(0xFF7C4DFF)
val PurpleLight = Color(0xFFD1C4E9)
val WarmCream = Color(0xFFFAF3E0)
val LightBeige = Color(0xFFF5F0E6)
val SurfaceLight = Color(0xFFFFF8E7)
val BorderTan = Color(0xFFE8DCC8)
val DarkBrown = Color(0xFF5D4037)
val WarmBrown = Color(0xFFA0896C)
val AccentRed = Color(0xFFFF5252)
val StatusGreen = Color(0xFF4CAF50)
val TextDark = Color(0xFF333333)
val TextMuted = Color(0xFFBBA88C)
val TextHint = Color(0xFF999999)

private val AniMindColors = lightColorScheme(
    primary = Purple,
    onPrimary = Color.White,
    background = WarmCream,
    surface = Color.White,
    onSurface = DarkBrown,
    error = AccentRed,
)

@Composable
fun AniMindTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = AniMindColors,
        content = content,
    )
}
