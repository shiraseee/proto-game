import SwiftUI

struct MemoryView: View {
    @State private var memories: [Memory] = []
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if memories.isEmpty {
                    emptyState
                } else {
                    memoryList
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !memories.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear All", role: .destructive) {
                            showClearAlert = true
                        }
                        .foregroundColor(Color(hex: 0xFF5252))
                    }
                }
            }
            .alert("Clear All Memories?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    DatabaseService.shared.clearAllMemories()
                    loadMemories()
                }
            } message: {
                Text("This will permanently delete all of Pixel's memories. This cannot be undone.")
            }
            .onAppear { loadMemories() }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🧠")
                .font(.system(size: 48))
            Text("No memories yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: 0x5D4037))
            Text("Chat with Pixel to create memories!")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0xBBA88C))
        }
    }

    // MARK: - Memory List

    private var memoryList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(memories.count) memor\(memories.count == 1 ? "y" : "ies")")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: 0xA0896C))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            List {
                ForEach(memories) { memory in
                    memoryCard(memory)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .onDelete { offsets in
                    for index in offsets {
                        DatabaseService.shared.deleteMemory(id: memories[index].id)
                    }
                    loadMemories()
                }
            }
            .listStyle(.plain)
            .refreshable { loadMemories() }
        }
    }

    private func memoryCard(_ memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(memory.content)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0x333333))
                .lineSpacing(3)

            HStack {
                Text(memory.formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0xA0896C))

                Spacer()

                // Importance dots
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i < memory.importanceStars
                                  ? Color(hex: 0x7C4DFF)
                                  : Color(hex: 0x7C4DFF, alpha: 0.15))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
    }

    // MARK: - Data

    private func loadMemories() {
        memories = DatabaseService.shared.getAllMemories()
    }
}
