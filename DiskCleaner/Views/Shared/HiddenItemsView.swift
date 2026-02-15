import SwiftUI

struct HiddenItemsView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        List {
            ForEach(appVM.hiddenNodes) { node in
                HStack(spacing: 10) {
                    if node.isDirectory {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 16)
                    } else {
                        let category = FileTypeClassifier.classify(url: node.url)
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                            .frame(width: 16)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.name)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(node.url.path(percentEncoded: false))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Text(node.formattedSize)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    Button("Show") {
                        appVM.unhideNode(node)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .safeAreaInset(edge: .bottom) {
            if appVM.hiddenNodes.count > 1 {
                HStack {
                    Spacer()
                    Button("Show All") {
                        appVM.unhideAll()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(.bar)
            }
        }
        .navigationTitle("Hidden Items")
    }
}
