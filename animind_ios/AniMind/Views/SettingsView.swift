import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var keyInput = ""
    @State private var showSaved = false
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    apiKeySection
                    statusSection
                    aboutSection
                }
                .padding(16)
            }
            .background(Color(hex: 0xFAF3E0))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Gemini API Key", systemImage: "key.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0x5D4037))

            Text("Required for Pixel to talk. Get one at aistudio.google.com/apikey")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0xA0896C))

            SecureField("Enter your API key", text: $keyInput)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(hex: 0xF5F0E6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                Button {
                    appState.setApiKey(keyInput)
                    showSaved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSaved = false
                    }
                } label: {
                    Text(showSaved ? "Saved!" : "Save Key")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: 0x7C4DFF))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if appState.hasApiKey {
                    Button {
                        showClearAlert = true
                    } label: {
                        Text("Clear")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: 0xFF5252))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: 0xFF5252), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        .alert("Clear API Key?", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                keyInput = ""
                appState.setApiKey("")
            }
        } message: {
            Text("Pixel won't be able to talk without an API key.")
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 0) {
            statusRow(
                label: "API Key",
                value: appState.hasApiKey ? "Configured" : "Not set",
                color: appState.hasApiKey ? Color(hex: 0x4CAF50) : Color(hex: 0xFF5252)
            )
            Divider()
            statusRow(
                label: "Days together",
                value: "\(appState.dayCount)",
                color: Color(hex: 0x7C4DFF)
            )
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
    }

    private func statusRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0x5D4037))
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .padding(16)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0x5D4037))

            Text("AniMind is a virtual pet with persistent memory, powered by AI. Pixel remembers your conversations and grows with you.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x666666))
                .lineSpacing(3)

            Text("🔒 Memories are stored locally and never leave your device.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0xA0896C))

            Text("Built with SwiftUI + SQLite + Gemini")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0xA0896C))

            Spacer().frame(height: 4)

            HStack {
                Spacer()
                Text("AniMind v1.0.0 — Native iOS")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0xCCCCCC))
                Spacer()
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
    }
}
