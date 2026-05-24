import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Thought.createdAt) private var thoughts: [Thought]
    @State private var newThought = ""
    @State private var now = Date()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ThoughtDump")
                    .font(.headline)
                Spacer()
                Text("\(thoughts.count) thoughts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Thought list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(thoughts) { thought in
                            ThoughtBubble(thought: thought, now: now, onDelete: {
                                modelContext.delete(thought)
                            }, onEditDone: {
                                isInputFocused = true
                            })
                            .id(thought.id)
                        }
                    }
                    .padding(12)
                }
                .onChange(of: thoughts.count) {
                    if let last = thoughts.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            HStack(spacing: 8) {
                TextField("What's on your mind?", text: $newThought)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .onSubmit(addThought)

                Button(action: addThought) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .disabled(newThought.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
        }
        .frame(width: 360, height: 480)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            // Refocus input whenever our panel becomes key (including reopen)
            if let window = notification.object as? NSWindow,
               window == NSApp.keyWindow {
                isInputFocused = true
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            now = Date()
        }
    }

    private func addThought() {
        let text = newThought.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let thought = Thought(content: text)
        modelContext.insert(thought)
        newThought = ""
    }

}
