import SwiftUI
import SwiftData

struct AdvisorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AdvisorMessageRecord.timestamp) private var messages: [AdvisorMessageRecord]
    @Query private var catches: [CatchRecord]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundColor(.pkDark)
                    Text("Palakaya Advisor").font(.system(size: 20, weight: .bold))
                }
                Text("Catch and market guidance based on your records.").font(.system(size: 13)).foregroundColor(.pkSub)
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
                    }
                    .padding(.horizontal, 20)
                    .id("bottom")
                }
                .onChange(of: messages.count) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                LabelCaps(text: "Suggested")
                VStack(spacing: 8) {
                    ForEach(Array(ADVISOR_SUGGESTIONS.enumerated()), id: \.offset) { _, s in
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
                    }
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

    private func ask(_ question: String) {
        modelContext.insert(AdvisorMessageRecord(isUser: true, text: question))
        let reply = Advisor.reply(to: question, catches: catches)
        modelContext.insert(AdvisorMessageRecord(isUser: false, text: reply))
        try? modelContext.save()
    }
}
