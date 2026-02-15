import SwiftUI

struct SuggestionsListView: View {
    let category: SpaceWasterCategory
    @Environment(AppViewModel.self) private var appVM

    private var suggestions: [SpaceWaster] {
        appVM.suggestionsVM.suggestions.filter { $0.category == category }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.riskLevel == .safe ? .green : .orange)

                VStack(alignment: .leading) {
                    Text(category.rawValue)
                        .font(.title3.bold())
                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                riskBadge
            }
            .padding()

            Divider()

            // List of items
            List {
                ForEach(suggestions) { suggestion in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(suggestion.url.lastPathComponent)
                                .lineLimit(1)
                            Text(suggestion.url.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }

                        Spacer()

                        Text(suggestion.formattedSize)
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Button {
                            appVM.navigateToDirectory(url: suggestion.url)
                        } label: {
                            Image(systemName: "arrow.right.circle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Explore in disk view")

                        Button("Clean") {
                            appVM.deleteSuggestion(suggestion)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)
        }
    }

    private var riskBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(category.riskLevel == .safe ? .green : .orange)
                .frame(width: 8, height: 8)
            Text(category.riskLevel.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.fill.tertiary, in: Capsule())
    }
}
