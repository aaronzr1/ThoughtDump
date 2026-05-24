import SwiftUI

struct ThoughtBubble: View {
    @Bindable var thought: Thought
    let now: Date
    var onDelete: () -> Void
    var onEditDone: () -> Void
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isEditFocused: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("", text: $editText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .focused($isEditFocused)
                        .onSubmit {
                            commitEdit()
                        }
                        .onExitCommand {
                            cancelEdit()
                        }
                } else {
                    Text(thought.content)
                }

                Text(thought.createdAt.relativeDescription(to: now))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

            Spacer(minLength: 40)
        }
        .contextMenu {
            Button("Edit") {
                editText = thought.content
                isEditing = true
                // Focus needs a tick to resolve after the view updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isEditFocused = true
                }
            }
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(thought.content, forType: .string)
            }
            Divider()
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            thought.content = trimmed
        }
        isEditing = false
        onEditDone()
    }

    private func cancelEdit() {
        isEditing = false
        onEditDone()
    }
}

extension Date {
    func relativeDescription(to now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: now)
    }
}
