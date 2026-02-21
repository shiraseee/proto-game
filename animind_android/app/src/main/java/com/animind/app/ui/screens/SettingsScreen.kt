package com.animind.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.animind.app.ui.theme.*
import com.animind.app.viewmodels.AppViewModel
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(viewModel: AppViewModel, modifier: Modifier = Modifier) {
    val apiKey by viewModel.apiKey.collectAsState()
    val dayCount by viewModel.dayCount.collectAsState()
    var keyInput by remember { mutableStateOf("") }
    var showSaved by remember { mutableStateOf(false) }
    var showClearDialog by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(WarmCream)
    ) {
        TopAppBar(title = { Text("Settings") })

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // API Key section
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(2.dp, RoundedCornerShape(16.dp))
                    .background(Color.White, RoundedCornerShape(16.dp))
                    .padding(16.dp),
            ) {
                Text("Gemini API Key", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DarkBrown)
                Spacer(Modifier.height(4.dp))
                Text(
                    "Required for Pixel to talk. Get one at aistudio.google.com/apikey",
                    fontSize = 12.sp,
                    color = WarmBrown,
                )
                Spacer(Modifier.height(12.dp))

                TextField(
                    value = keyInput,
                    onValueChange = { keyInput = it },
                    placeholder = { Text("Enter your API key") },
                    visualTransformation = PasswordVisualTransformation(),
                    singleLine = true,
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = LightBeige,
                        unfocusedContainerColor = LightBeige,
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                    ),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(Modifier.height(12.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(
                        onClick = {
                            viewModel.setApiKey(keyInput)
                            showSaved = true
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Purple),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.weight(1f),
                    ) {
                        Text(if (showSaved) "Saved!" else "Save Key")
                    }

                    if (apiKey.isNotBlank()) {
                        OutlinedButton(
                            onClick = { showClearDialog = true },
                            shape = RoundedCornerShape(12.dp),
                        ) {
                            Text("Clear", color = AccentRed)
                        }
                    }
                }
            }

            // Status section
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(2.dp, RoundedCornerShape(16.dp))
                    .background(Color.White, RoundedCornerShape(16.dp)),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("API Key", fontSize = 14.sp, color = DarkBrown)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            Modifier
                                .size(8.dp)
                                .background(
                                    if (apiKey.isNotBlank()) StatusGreen else AccentRed,
                                    CircleShape,
                                )
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(
                            if (apiKey.isNotBlank()) "Configured" else "Not set",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = if (apiKey.isNotBlank()) StatusGreen else AccentRed,
                        )
                    }
                }

                Divider(color = BorderTan)

                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Days together", fontSize = 14.sp, color = DarkBrown)
                    Text(
                        "$dayCount",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Purple,
                    )
                }
            }

            // About section
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(2.dp, RoundedCornerShape(16.dp))
                    .background(Color.White, RoundedCornerShape(16.dp))
                    .padding(16.dp),
            ) {
                Text("About", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DarkBrown)
                Spacer(Modifier.height(8.dp))
                Text(
                    "AniMind is a virtual pet with persistent memory, powered by AI. Pixel remembers your conversations and grows with you.",
                    fontSize = 13.sp,
                    color = Color(0xFF666666),
                    lineHeight = 19.sp,
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    "🔒 Memories are stored locally and never leave your device.",
                    fontSize = 12.sp,
                    color = WarmBrown,
                )
                Text(
                    "Built with Jetpack Compose + SQLite + Gemini",
                    fontSize = 12.sp,
                    color = WarmBrown,
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    "AniMind v1.0.0 — Native Android",
                    fontSize = 11.sp,
                    color = Color(0xFFCCCCCC),
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center,
                )
            }
        }
    }

    // Clear API key dialog
    if (showClearDialog) {
        AlertDialog(
            onDismissRequest = { showClearDialog = false },
            title = { Text("Clear API Key?") },
            text = { Text("Pixel won't be able to talk without an API key.") },
            confirmButton = {
                TextButton(onClick = {
                    keyInput = ""
                    viewModel.setApiKey("")
                    showClearDialog = false
                }) { Text("Clear", color = AccentRed) }
            },
            dismissButton = {
                TextButton(onClick = { showClearDialog = false }) { Text("Cancel") }
            },
        )
    }
}
