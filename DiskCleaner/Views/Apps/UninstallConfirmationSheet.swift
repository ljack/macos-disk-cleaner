import SwiftUI

struct UninstallConfirmationSheet: View {
    @Environment(AppViewModel.self) private var appVM

    private var uninstallerVM: AppUninstallerViewModel {
        appVM.uninstallerVM
    }

    var body: some View {
        if let app = uninstallerVM.appToUninstall {
            VStack(spacing: 16) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 48, height: 48)

                Text("Uninstall \(app.name)?")
                    .font(.title2.bold())

                Text("The app and all associated data will be moved to Trash.")
                    .foregroundStyle(.secondary)

                // Items list
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        // App bundle
                        HStack {
                            Image(systemName: "app.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 16)
                            Text(app.bundleURL.lastPathComponent)
                                .lineLimit(1)
                            Spacer()
                            Text(app.formattedBundleSize)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        if !app.associatedFiles.isEmpty {
                            Divider()
                        }

                        // Associated files
                        ForEach(app.associatedFiles) { file in
                            HStack {
                                Image(systemName: file.category.icon)
                                    .foregroundStyle(.orange)
                                    .frame(width: 16)
                                Text(file.url.lastPathComponent)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Text(file.formattedSize)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 200)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))

                // Total
                HStack {
                    Text("Total:")
                        .font(.callout.bold())
                    Spacer()
                    Text(app.formattedTotalSize)
                        .font(.callout.bold().monospacedDigit())
                }
                .padding(.horizontal)

                if let error = uninstallerVM.uninstallError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Buttons
                HStack {
                    Button("Cancel") {
                        uninstallerVM.cancelUninstall()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("Move to Trash") {
                        appVM.performAppUninstall()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(uninstallerVM.isUninstalling)
                }
            }
            .padding(24)
            .frame(width: 450)
        }
    }
}
