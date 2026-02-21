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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.animind.app.models.Memory
import com.animind.app.ui.theme.*
import com.animind.app.viewmodels.AppViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemoryScreen(viewModel: AppViewModel, modifier: Modifier = Modifier) {
    val memories by viewModel.memories.collectAsState()
    var showClearDialog by remember { mutableStateOf(false) }
    var deleteTarget by remember { mutableStateOf<Memory?>(null) }

    LaunchedEffect(Unit) { viewModel.loadMemories() }

    Column(modifier = modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("Memories") },
            actions = {
                if (memories.isNotEmpty()) {
                    TextButton(onClick = { showClearDialog = true }) {
                        Text("Clear All", color = AccentRed, fontWeight = FontWeight.SemiBold)
                    }
                }
            },
        )

        if (memories.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("🧠", fontSize = 48.sp)
                    Spacer(Modifier.height(12.dp))
                    Text("No memories yet", fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = DarkBrown)
                    Spacer(Modifier.height(4.dp))
                    Text("Chat with Pixel to create memories!", fontSize = 14.sp, color = TextMuted)
                }
            }
        } else {
            // Header
            Text(
                "${memories.size} memor${if (memories.size == 1) "y" else "ies"}",
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = WarmBrown,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
            )

            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(memories, key = { it.id }) { memory ->
                    MemoryCard(
                        memory = memory,
                        onDelete = { deleteTarget = memory },
                    )
                }
                item { Spacer(Modifier.height(8.dp)) }
            }
        }
    }

    // Clear all dialog
    if (showClearDialog) {
        AlertDialog(
            onDismissRequest = { showClearDialog = false },
            title = { Text("Clear All Memories?") },
            text = { Text("This will permanently delete all of Pixel's memories. This cannot be undone.") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.clearAllMemories()
                    showClearDialog = false
                }) { Text("Clear All", color = AccentRed) }
            },
            dismissButton = {
                TextButton(onClick = { showClearDialog = false }) { Text("Cancel") }
            },
        )
    }

    // Delete single dialog
    deleteTarget?.let { memory ->
        AlertDialog(
            onDismissRequest = { deleteTarget = null },
            title = { Text("Delete Memory?") },
            text = { Text("\"${memory.content}\"") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteMemory(memory.id)
                    deleteTarget = null
                }) { Text("Delete", color = AccentRed) }
            },
            dismissButton = {
                TextButton(onClick = { deleteTarget = null }) { Text("Cancel") }
            },
        )
    }
}

@Composable
private fun MemoryCard(memory: Memory, onDelete: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(2.dp, RoundedCornerShape(12.dp))
            .background(Color.White, RoundedCornerShape(12.dp))
            .padding(12.dp),
    ) {
        Text(
            memory.content,
            fontSize = 14.sp,
            color = TextDark,
            lineHeight = 20.sp,
        )
        Spacer(Modifier.height(8.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(memory.formattedDate, fontSize = 11.sp, color = WarmBrown)

            // Importance dots
            Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                repeat(5) { i ->
                    Box(
                        Modifier
                            .size(6.dp)
                            .background(
                                if (i < memory.importanceStars) Purple else Purple.copy(alpha = 0.15f),
                                CircleShape,
                            )
                    )
                }
            }

            TextButton(onClick = onDelete) {
                Text("Delete", fontSize = 11.sp, color = AccentRed)
            }
        }
    }
}
