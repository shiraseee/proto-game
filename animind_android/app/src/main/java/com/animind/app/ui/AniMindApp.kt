package com.animind.app.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.animind.app.ui.screens.HomeScreen
import com.animind.app.ui.screens.MemoryScreen
import com.animind.app.ui.screens.SettingsScreen
import com.animind.app.ui.theme.AniMindTheme
import com.animind.app.viewmodels.AppViewModel

@Composable
fun AniMindApp(viewModel: AppViewModel = viewModel()) {
    LaunchedEffect(Unit) {
        viewModel.initialize()
    }

    AniMindTheme {
        var selectedTab by rememberSaveable { mutableIntStateOf(0) }

        Scaffold(
            bottomBar = {
                NavigationBar {
                    NavigationBarItem(
                        selected = selectedTab == 0,
                        onClick = { selectedTab = 0 },
                        icon = { Icon(Icons.Filled.ChatBubble, "Chat") },
                        label = { Text("Chat") },
                    )
                    NavigationBarItem(
                        selected = selectedTab == 1,
                        onClick = {
                            selectedTab = 1
                            viewModel.loadMemories()
                        },
                        icon = { Icon(Icons.Filled.Psychology, "Memories") },
                        label = { Text("Memories") },
                    )
                    NavigationBarItem(
                        selected = selectedTab == 2,
                        onClick = { selectedTab = 2 },
                        icon = { Icon(Icons.Filled.Settings, "Settings") },
                        label = { Text("Settings") },
                    )
                }
            }
        ) { padding ->
            when (selectedTab) {
                0 -> HomeScreen(viewModel, Modifier.padding(padding))
                1 -> MemoryScreen(viewModel, Modifier.padding(padding))
                2 -> SettingsScreen(viewModel, Modifier.padding(padding))
            }
        }
    }
}
