import SwiftUI
import SwiftData

struct AdvisorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AdvisorMessageRecord.timestamp) private var allMessages: [AdvisorMessageRecord]
    private var messages: [AdvisorMessageRecord] { allMessages.filter { $0.ownerID == appState.currentUserID } }
    @State private var draft = ""
    @State private var isThinking = false
    @Query private var allCatches: [CatchRecord]
    private var catches: [CatchRecord] { allCatches.owned(by: appState.currentUserID) }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundColor(.pkDark)
                    Text("Palakaya Advisor").font(.system(size: 20, weight: .bold))
                }
                Text(appState.isBuyer ? "Ask about fish prices, fair offers and buying. You can type in English or Filipino." : "Ask about your catch, fish prices and selling. You can type in English or Filipino.").font(.system(size: 13)).foregroundColor(.pkSub)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { m in
                            bubble(m)
                        }
                        if isThinking {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Thinking…").font(.system(size: 13)).foregroundColor(.pkSub)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Color.pkSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(.horizontal, 20)
                    .id("bottom")
                }
                .onChange(of: isThinking) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: messages.count) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if messages.count <= 2 {
                LabelCaps(text: "Suggested")
                VStack(spacing: 8) {
                    ForEach(Array((appState.isBuyer ? BUYER_ADVISOR_SUGGESTIONS : ADVISOR_SUGGESTIONS).enumerated()), id: \.offset) { _, s in
                        Button {
                            ask(s)
                        } label: {
                            Text(s)
                                .font(.system(size: 13))
                                .foregroundColor(.pkText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pkBorder))
                        }
                        .buttonStyle(.plain)
                        .disabled(isThinking)
                    }
                }
                }

                HStack(spacing: 8) {
                    TextField(appState.isBuyer ? "Ask about fish prices or buying…" : "Ask about your catch or fish prices…", text: $draft, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(1...4)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .frame(minHeight: 48)
                        .background(Color.pkSurface)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pkBorder))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Button {
                        ask(draft)
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(canSend ? Color.pkDark : Color.pkBorder)
                            .clipShape(Circle())
                    }
                    .disabled(!canSend)
                    .accessibilityLabel("Send question")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.pkBg)
        .navigationBarHidden(true)
    }

    private func bubble(_ m: AdvisorMessageRecord) -> some View {
        Text(m.text)
            .font(.system(size: 13.5))
            .lineSpacing(3)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(m.isUser ? Color.pkDark : Color.pkSurface2)
            .foregroundColor(m.isUser ? .white : .pkText)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .frame(maxWidth: 280, alignment: m.isUser ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: m.isUser ? .trailing : .leading)
    }

    private var canSend: Bool {
        !isThinking && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func ask(_ question: String) {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !isThinking else { return }
        let history = messages
        draft = ""
        isThinking = true
        Task {
            defer { isThinking = false }
            do {
                try await AdvisorController(context: modelContext)
                    .ask(q, catches: catches, history: history, appState: appState)
            } catch {
                appState.errorMessage = "Your message could not be saved. Please try again."
            }
        }
    }
}
