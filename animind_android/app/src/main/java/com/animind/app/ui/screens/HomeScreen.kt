package com.animind.app.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.animind.app.models.ChatMessage
import com.animind.app.models.MessageRole
import com.animind.app.services.SpeechService
import com.animind.app.ui.theme.*
import com.animind.app.viewmodels.AppViewModel

@Composable
fun HomeScreen(viewModel: AppViewModel, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val messages by viewModel.messages.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val dayCount by viewModel.dayCount.collectAsState()
    val mood by viewModel.mood.collectAsState()
    val greeting by viewModel.greeting.collectAsState()
    var inputText by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    // Speech
    val speechService = remember { SpeechService(context) }
    val isListening by speechService.isListening.collectAsState()
    val speechAvailable by speechService.isAvailable.collectAsState()
    val transcript by speechService.transcript.collectAsState()

    // Mic permission
    var hasMicPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)
                    == PackageManager.PERMISSION_GRANTED
        )
    }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        hasMicPermission = granted
        if (granted) speechService.initialize()
    }

    // Init speech
    LaunchedEffect(Unit) {
        if (hasMicPermission) {
            speechService.initialize()
        }
        speechService.onFinalResult = { text ->
            inputText = text
            viewModel.sendMessage(text)
            inputText = ""
        }
    }

    // Show greeting
    LaunchedEffect(greeting) {
        viewModel.showGreetingIfNeeded()
    }

    // Update text field from partial results
    LaunchedEffect(transcript) {
        if (isListening) {
            inputText = transcript
        }
    }

    // Scroll to bottom
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    DisposableEffect(Unit) {
        onDispose { speechService.destroy() }
    }

    // Bounce animation
    val infiniteTransition = rememberInfiniteTransition(label = "bounce")
    val bounceOffset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = -10f,
        animationSpec = infiniteRepeatable(tween(1600), RepeatMode.Reverse),
        label = "bounceOffset",
    )

    // Pulse animation for mic
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(tween(800), RepeatMode.Reverse),
        label = "pulseScale",
    )

    Column(modifier = modifier.fillMaxSize()) {
        // Pet area
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .fillMaxWidth()
                .background(SurfaceLight)
                .padding(vertical = 10.dp),
        ) {
            Text(
                "Day $dayCount of your life together",
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                color = WarmBrown,
                letterSpacing = 0.5.sp,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                mood.emoji,
                fontSize = 52.sp,
                modifier = Modifier.offset { IntOffset(0, bounceOffset.dp.roundToPx()) },
            )
            Spacer(Modifier.height(4.dp))
            Text(
                mood.label,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = Purple,
                modifier = Modifier
                    .background(Purple.copy(alpha = 0.08f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 12.dp, vertical = 3.dp),
            )
            Spacer(Modifier.height(4.dp))
            Text("Pixel", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = DarkBrown)
        }

        Divider(color = BorderTan, thickness = 1.dp)

        // Chat area
        Box(Modifier.weight(1f).fillMaxWidth()) {
            if (messages.isEmpty()) {
                Text(
                    "Say something to Pixel!",
                    color = TextMuted,
                    fontSize = 14.sp,
                    modifier = Modifier.align(Alignment.Center),
                )
            } else {
                val screenWidth = LocalConfiguration.current.screenWidthDp.dp
                LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxSize().padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    items(messages, key = { it.id }) { msg ->
                        MessageBubble(msg, screenWidth.value * 0.78f)
                    }
                    if (isLoading) {
                        item { TypingIndicator() }
                    }
                }
            }
        }

        Divider(color = BorderTan, thickness = 1.dp)

        // Input area
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color.White)
                .padding(12.dp),
        ) {
            // Listening indicator
            if (isListening) {
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                ) {
                    Box(
                        Modifier
                            .size(8.dp)
                            .background(AccentRed, CircleShape)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text("Listening...", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = AccentRed)
                }
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                // Mic button
                if (speechAvailable || !hasMicPermission) {
                    IconButton(
                        onClick = {
                            if (!hasMicPermission) {
                                permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                            } else {
                                speechService.toggleListening()
                            }
                        },
                        enabled = !isLoading,
                        modifier = Modifier
                            .size(44.dp)
                            .scale(if (isListening) pulseScale else 1f)
                            .background(
                                if (isListening) AccentRed else LightBeige,
                                CircleShape,
                            ),
                    ) {
                        Icon(
                            if (isListening) Icons.Filled.Stop else Icons.Filled.Mic,
                            contentDescription = "Voice",
                            tint = if (isListening) Color.White else Purple,
                            modifier = Modifier.size(22.dp),
                        )
                    }
                    Spacer(Modifier.width(8.dp))
                }

                // Text field
                TextField(
                    value = inputText,
                    onValueChange = { inputText = it },
                    enabled = !isLoading && !isListening,
                    placeholder = {
                        Text(
                            if (isListening) "Speak now..." else "Talk to Pixel...",
                            color = TextHint,
                        )
                    },
                    singleLine = true,
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = LightBeige,
                        unfocusedContainerColor = LightBeige,
                        disabledContainerColor = LightBeige,
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                        disabledIndicatorColor = Color.Transparent,
                    ),
                    shape = RoundedCornerShape(22.dp),
                    textStyle = TextStyle(fontSize = 15.sp),
                    modifier = Modifier.weight(1f),
                )

                Spacer(Modifier.width(8.dp))

                // Send button
                IconButton(
                    onClick = {
                        viewModel.sendMessage(inputText)
                        inputText = ""
                    },
                    enabled = !isLoading,
                    modifier = Modifier
                        .size(44.dp)
                        .background(
                            if (inputText.isBlank() || isLoading) PurpleLight else Purple,
                            CircleShape,
                        ),
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Send",
                        tint = Color.White,
                        modifier = Modifier.size(20.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun MessageBubble(msg: ChatMessage, maxWidth: Float) {
    val isUser = msg.role == MessageRole.USER
    val isError = msg.role == MessageRole.ERROR

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start,
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = maxWidth.dp)
                .shadow(
                    if (isUser) 0.dp else 2.dp,
                    RoundedCornerShape(
                        topStart = 16.dp, topEnd = 16.dp,
                        bottomStart = if (isUser) 16.dp else 4.dp,
                        bottomEnd = if (isUser) 4.dp else 16.dp,
                    )
                )
                .background(
                    when {
                        isUser -> Purple
                        isError -> Color(0xFFFFEBEE)
                        else -> Color.White
                    },
                    RoundedCornerShape(
                        topStart = 16.dp, topEnd = 16.dp,
                        bottomStart = if (isUser) 16.dp else 4.dp,
                        bottomEnd = if (isUser) 4.dp else 16.dp,
                    ),
                )
                .padding(12.dp),
        ) {
            if (!isUser && !isError) {
                Text(
                    "Pixel",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = Purple,
                )
                Spacer(Modifier.height(4.dp))
            }
            Text(
                msg.text,
                fontSize = 15.sp,
                color = if (isUser) Color.White else TextDark,
                lineHeight = 21.sp,
            )
        }
    }
}

@Composable
private fun TypingIndicator() {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(vertical = 8.dp),
    ) {
        CircularProgressIndicator(
            modifier = Modifier.size(16.dp),
            strokeWidth = 2.dp,
            color = Purple,
        )
        Spacer(Modifier.width(8.dp))
        Text(
            "Pixel is thinking...",
            fontSize = 13.sp,
            color = Purple.copy(alpha = 0.8f),
            fontStyle = FontStyle.Italic,
        )
    }
}
