import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var speech = SpeechService()
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var greetingShown = false
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                petArea
                Divider().background(Color(hex: 0xE8DCC8))
                chatArea
                inputArea
            }
            .navigationTitle("🐣 AniMind")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            speech.requestPermission()
            speech.onFinalResult = { text in
                inputText = text
                sendMessage()
            }
            startBounceAnimation()
        }
        .onChange(of: appState.greeting) {
            showGreetingIfNeeded()
        }
        .onChange(of: speech.transcript) {
            if speech.isListening {
                inputText = speech.transcript
            }
        }
    }

    // MARK: - Pet Area

    private var petArea: some View {
        VStack(spacing: 4) {
            Text("Day \(appState.dayCount) of your life together")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: 0xA0896C))
                .tracking(0.5)

            Text(appState.moodEmoji)
                .font(.system(size: 52))
                .offset(y: bounceOffset)

            Text(appState.moodLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: 0x7C4DFF))
                .padding(.horizontal, 12)
                .padding(.vertical, 3)
                .background(Color(hex: 0x7C4DFF, alpha: 0.08))
                .clipShape(Capsule())

            Text("Pixel")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: 0x5D4037))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xFFF8E7))
    }

    // MARK: - Chat Area

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }
                        if isLoading {
                            typingIndicator
                        }
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text("Say something to Pixel!")
                .foregroundColor(Color(hex: 0xBBA88C))
                .font(.system(size: 14))
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 80)
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isUser = msg.role == .user
        let isError = msg.role == .error

        return HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: .leading, spacing: 4) {
                if !isUser && !isError {
                    Text("Pixel")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0x7C4DFF))
                }
                Text(msg.text)
                    .font(.system(size: 15))
                    .foregroundColor(isUser ? .white : Color(hex: 0x333333))
                    .lineSpacing(4)
            }
            .padding(12)
            .background(
                isUser ? Color(hex: 0x7C4DFF)
                : isError ? Color(hex: 0xFFEBEE)
                : .white
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                isError
                    ? RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xFFCDD2), lineWidth: 1)
                    : nil
            )
            .shadow(color: isUser ? .clear : .black.opacity(0.05), radius: 4, y: 1)

            if !isUser { Spacer(minLength: 60) }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(Color(hex: 0x7C4DFF))
                .scaleEffect(0.8)
            Text("Pixel is thinking...")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x7C4DFF).opacity(0.8))
                .italic()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: 0xE8DCC8))

            if speech.isListening {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: 0xFF5252))
                        .frame(width: 8, height: 8)
                    Text("Listening...")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0xFF5252))
                }
                .padding(.top, 8)
            }

            HStack(spacing: 8) {
                // Mic button
                if speech.isAvailable {
                    Button {
                        speech.toggleListening()
                    } label: {
                        Image(systemName: speech.isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 18))
                            .foregroundColor(speech.isListening ? .white : Color(hex: 0x7C4DFF))
                            .frame(width: 44, height: 44)
                            .background(speech.isListening ? Color(hex: 0xFF5252) : Color(hex: 0xF5F0E6))
                            .clipShape(Circle())
                            .scaleEffect(speech.isListening ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: speech.isListening)
                    }
                    .disabled(isLoading)
                }

                // Text field
                TextField(speech.isListening ? "Speak now..." : "Talk to Pixel...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0xF5F0E6))
                    .clipShape(Capsule())
                    .disabled(isLoading || speech.isListening)
                    .onSubmit { sendMessage() }

                // Send button
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                                ? Color(hex: 0xD1C4E9)
                                : Color(hex: 0x7C4DFF)
                        )
                        .clipShape(Circle())
                }
                .disabled(isLoading)
            }
            .padding(12)
        }
        .background(.white)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isLoading else { return }
        inputText = ""

        messages.append(ChatMessage(text: text, role: .user))
        isLoading = true

        Task {
            do {
                let response = try await GeminiService.chatWithPet(text, apiKey: appState.apiKey)
                appState.incrementChat()
                messages.append(ChatMessage(text: response, role: .pet))
            } catch {
                messages.append(ChatMessage(
                    text: error.localizedDescription,
                    role: .error
                ))
            }
            isLoading = false
        }
    }

    private func showGreetingIfNeeded() {
        guard !greetingShown, !appState.greeting.isEmpty else { return }
        greetingShown = true
        messages.append(ChatMessage(text: appState.greeting, role: .pet))
    }

    private func startBounceAnimation() {
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            bounceOffset = -10
        }
    }
}
