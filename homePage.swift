import SwiftUI

struct HomeView: View {

    // MARK: - Package Data

    @State private var packages: [Package] = []

    // MARK: - UI State

    @State private var showPackages = false
    @State private var isLoading = false

    @State private var packagesNeedingUpdate: Set<String> = []
    @State private var packagesWithConflict: Set<String> = []

    // MARK: - Selected Package

    @State private var selectedPackageId = ""
    @State private var selectedPackagePath = ""
    @State private var selectedPackageName = ""
    @State private var selectedFiles: [PackageFile] = []

    // MARK: - Navigation

    @State private var showHomeView2 = false

    // MARK: - Username

    @State private var username = ""

    // MARK: - Sign Out

    var onSignOut: () -> Void

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                // MARK: - Background

                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.14),
                        Color(red: 0.10, green: 0.08, blue: 0.24),
                        Color(red: 0.22, green: 0.10, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 24
                    ) {

                        // MARK: - Welcome

                        HStack {

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text("Welcome")
                                    .font(
                                        .system(
                                            size: 24,
                                            weight: .bold
                                        )
                                    )
                                    .foregroundStyle(.white)

                                Text(username)
                                    .font(
                                        .system(size: 14)
                                    )
                                    .foregroundStyle(
                                        .white.opacity(0.55)
                                    )
                            }

                            Spacer()

                            // MARK: - Sign Out

                            Button {

                                AuthManager.shared.signOut()
                                onSignOut()

                            } label: {

                                Image(
                                    systemName:
                                        "rectangle.portrait.and.arrow.right"
                                )
                                .font(
                                    .system(
                                        size: 20,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(.white)
                                .frame(
                                    width: 44,
                                    height: 44
                                )
                                .background(
                                    .white.opacity(0.08)
                                )
                                .clipShape(Circle())
                            }
                        }

                        // MARK: - Your Notebooks Button

                        Button {

                            if showPackages {

                                showPackages = false

                            } else {

                                loadPackages()
                            }

                        } label: {

                            HStack {

                                Image(
                                    systemName:
                                        "shippingbox"
                                )

                                Text("Your Notebooks")

                                Spacer()

                                if isLoading {

                                    ProgressView()
                                        .tint(.white)

                                } else {

                                    Image(
                                        systemName:
                                            showPackages
                                            ? "chevron.up"
                                            : "chevron.down"
                                    )
                                }
                            }
                            .font(
                                .system(
                                    size: 18,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.white)
                            .padding()
                            .frame(
                                maxWidth: .infinity
                            )
                            .background(
                                .white.opacity(0.08)
                            )
                            .overlay(
                                RoundedRectangle(
                                    cornerRadius: 16
                                )
                                .stroke(
                                    .white.opacity(0.12),
                                    lineWidth: 1
                                )
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 16
                                )
                            )
                        }
                        .disabled(isLoading)

                        // MARK: - Notebook List

                        if showPackages {

                            VStack(
                                alignment: .leading,
                                spacing: 14
                            ) {

                                ForEach(
                                    packages,
                                    id: \.id
                                ) { package in

                                    HStack(spacing: 0) {

                                        // MARK: - Notebook Card

                                        VStack(
                                            alignment: .leading,
                                            spacing: 12
                                        ) {

                                            // MARK: - Notebook Header

                                            HStack {

                                                Image(
                                                    systemName:
                                                        "book.closed.fill"
                                                )
                                                .font(
                                                    .system(size: 20)
                                                )
                                                .foregroundStyle(.white)

                                                Text(
                                                    package.path
                                                    ?? "Unknown Notebook"
                                                )
                                                .font(
                                                    .system(
                                                        size: 17,
                                                        weight: .semibold
                                                    )
                                                )
                                                .foregroundStyle(.white)
                                                .lineLimit(1)

                                                Spacer()
                                            }

                                            Divider()
                                                .overlay(
                                                    .white.opacity(0.1)
                                                )

                                            // MARK: - Package Metadata

                                            VStack(
                                                alignment: .leading,
                                                spacing: 6
                                            ) {

                                                Text("Package ID")
                                                    .font(
                                                        .system(
                                                            size: 12,
                                                            weight: .medium
                                                        )
                                                    )
                                                    .foregroundStyle(
                                                        .white.opacity(0.45)
                                                    )

                                                Text(package.id)
                                                    .font(
                                                        .system(size: 13)
                                                    )
                                                    .foregroundStyle(
                                                        .white.opacity(0.7)
                                                    )
                                                    .lineLimit(1)

                                                Text("Path")
                                                    .font(
                                                        .system(
                                                            size: 12,
                                                            weight: .medium
                                                        )
                                                    )
                                                    .foregroundStyle(
                                                        .white.opacity(0.45)
                                                    )

                                                Text(
                                                    package.path
                                                    ?? "Unknown"
                                                )
                                                .font(
                                                    .system(size: 13)
                                                )
                                                .foregroundStyle(
                                                    .white.opacity(0.7)
                                                )
                                                .lineLimit(1)

                                                Text("Last Modified")
                                                    .font(
                                                        .system(
                                                            size: 12,
                                                            weight: .medium
                                                        )
                                                    )
                                                    .foregroundStyle(
                                                        .white.opacity(0.45)
                                                    )

                                                Text(
                                                    formattedDate(
                                                        from: package.lastMod
                                                    )
                                                )
                                                .font(
                                                    .system(size: 13)
                                                )
                                                .foregroundStyle(
                                                    .white.opacity(0.7)
                                                )

                                                // MARK: - Sync Status

                                                syncStatusView(
                                                    package: package
                                                )
                                            }
                                        }
                                        .padding(18)
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                        .contentShape(Rectangle())

                                        // MARK: - Open Package

                                        .onTapGesture {

                                            openPackage(package)
                                        }

                                        // MARK: - Download / Sync Button

                                        Button {

                                            downloadPackage(
                                                package: package
                                            )

                                        } label: {

                                            Image(
                                                systemName:
                                                    syncIcon(
                                                        for: package
                                                    )
                                            )
                                            .font(
                                                .system(size: 22)
                                            )
                                            .foregroundStyle(
                                                .white.opacity(0.8)
                                            )
                                        }
                                        .frame(
                                            width: 55,
                                            height: 55
                                        )
                                        .buttonStyle(.plain)
                                    }
                                    .background(
                                        .white.opacity(0.07)
                                    )
                                    .overlay(
                                        RoundedRectangle(
                                            cornerRadius: 18
                                        )
                                        .stroke(
                                            .white.opacity(0.12),
                                            lineWidth: 1
                                        )
                                    )
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 18
                                        )
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                }
            }

            // MARK: - Refresh Package Status

            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        loadPackages()

                    } label: {

                        Image(
                            systemName:
                                "arrow.clockwise"
                        )
                        .foregroundStyle(.white)
                    }
                }
            }

            // MARK: - Navigate to HomeView2

            .navigationDestination(
                isPresented: $showHomeView2
            ) {

                HomeView2(
                    packageId: selectedPackageId,
                    packagePath: selectedPackagePath,
                    packageName: selectedPackageName,
                    files: selectedFiles
                )
            }
        }

        // MARK: - Lifecycle

        .onAppear {

            username =
                AuthManager.shared.getUsername()
                ?? "Unknown User"
        }
    }

    // MARK: - Load Packages + Check Sync Status

    private func loadPackages() {

        isLoading = true

        Task {

            // Get latest package metadata from server.

            let receivedPackages =
                await ApiCallClass
                    .apicallobject
                    .getAllPackageMetadata()

            await MainActor.run {

                if let receivedPackages {

                    var packagesNeedingUpdate: Set<String> = []
                    var packagesWithConflict: Set<String> = []

                    // Each package is checked independently.

                    for package in receivedPackages {

                        let syncRecord =
                            SyncTable.shared.getRecord(
                                packageId: package.id
                            )

                        print("")
                        print("📦 Package:", package.id)
                        print(
                            "📁 Package path:",
                            package.path ?? "nil"
                        )
                        print(
                            "🌐 Server lastMod:",
                            package.lastMod
                        )

                        if let syncRecord {

                            print(
                                "💾 SyncTable lastMod:",
                                syncRecord.lastMod
                            )

                            print(
                                "⚠️ Conflict:",
                                syncRecord.conflict
                            )

                        } else {

                            print(
                                "💾 SyncTable record: nil"
                            )
                        }

                        // ------------------------------------------------
                        // NO SYNC RECORD
                        //
                        // This package has never synchronized.
                        // ------------------------------------------------

                        guard let syncRecord else {

                            print(
                                "🆕 No SyncTable record. Download required."
                            )

                            packagesNeedingUpdate.insert(
                                package.id
                            )

                            continue
                        }

                        // ------------------------------------------------
                        // CONFLICT
                        //
                        // Conflict belongs to THIS package only.
                        // ------------------------------------------------

                        if syncRecord.conflict {

                            print(
                                "⚠️ Package is in CONFLICT:",
                                package.id
                            )

                            packagesWithConflict.insert(
                                package.id
                            )

                            continue
                        }

                        // ------------------------------------------------
                        // SERVER > SYNCTABLE
                        //
                        // This package has a newer server version.
                        // ------------------------------------------------

                        if syncRecord.lastMod < package.lastMod {

                            print(
                                "⬇️ Server is newer. Download required."
                            )

                            packagesNeedingUpdate.insert(
                                package.id
                            )

                            continue
                        }

                        // ------------------------------------------------
                        // SERVER == SYNCTABLE
                        //
                        // This package is synchronized with server.
                        //
                        // Local timestamp is intentionally NOT checked
                        // here.
                        //
                        // DownloadApiClass handles the local/sync/server
                        // comparison when synchronization is requested.
                        // ------------------------------------------------

                        if syncRecord.lastMod == package.lastMod {

                            print(
                                "✅ Server == SyncTable"
                            )

                            continue
                        }

                        // ------------------------------------------------
                        // SERVER < SYNCTABLE
                        //
                        // Ignore this package state.
                        // ------------------------------------------------

                        if syncRecord.lastMod > package.lastMod {

                            print(
                                "ℹ️ SyncTable > Server"
                            )

                            print(
                                "Ignoring this case."
                            )

                            continue
                        }
                    }

                    packages =
                        receivedPackages

                    self.packagesNeedingUpdate =
                        packagesNeedingUpdate

                    self.packagesWithConflict =
                        packagesWithConflict

                    showPackages = true

                    print("")
                    print(
                        "✅ Received \(receivedPackages.count) packages"
                    )

                    print(
                        "⬇️ Packages needing download:",
                        packagesNeedingUpdate
                    )

                    print(
                        "⚠️ Packages with conflict:",
                        packagesWithConflict
                    )

                } else {

                    print(
                        "❌ Failed to receive packages"
                    )
                }

                isLoading = false
            }
        }
    }

    // MARK: - Sync Status View

    @ViewBuilder
    private func syncStatusView(
        package: Package
    ) -> some View {

        if packagesWithConflict.contains(package.id) {

            Text("Conflict")
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.orange)

        } else if packagesNeedingUpdate.contains(package.id) {

            Text("Update available")
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.8)
                )

        } else {

            Text("Synchronized")
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.8)
                )
        }
    }

    // MARK: - Sync Icon

    private func syncIcon(
        for package: Package
    ) -> String {

        if packagesWithConflict.contains(package.id) {

            return "exclamationmark.triangle"
        }

        if packagesNeedingUpdate.contains(package.id) {

            return "arrow.down.circle"
        }

        return "checkmark.circle"
    }

    // MARK: - Open Package

    private func openPackage(
        _ package: Package
    ) {

        selectedPackageId =
            package.id

        selectedPackagePath =
            package.path ?? ""

        Task {

            let files =
                await PackageManifestApiClass
                    .packageManifestObject
                    .getPackageManifest(
                        packageId: package.id
                    )

            await MainActor.run {

                if let files {

                    selectedPackageName =
                        URL(
                            fileURLWithPath:
                                package.path
                                ?? "Unknown Package"
                        )
                        .lastPathComponent

                    selectedFiles = files

                    print(
                        "📦 Package path:",
                        package.path ?? "nil"
                    )

                    print(
                        "📄 Received \(files.count) files"
                    )

                    showHomeView2 = true

                } else {

                    print(
                        "❌ Failed to get package manifest"
                    )
                }
            }
        }
    }

    // MARK: - Download Package

    private func downloadPackage(
        package: Package
    ) {

        Task {

            print(
                "📦 User selected package for synchronization"
            )

            print(
                "Package ID:",
                package.id
            )

            print(
                "Package path:",
                package.path ?? "nil"
            )

            let success =
                await DownloadApiClass
                    .shared
                    .downloadPackage(
                        package: package
                    )

            await MainActor.run {

                if success {

                    // DownloadApiClass has already updated
                    // the SyncTable record.

                    if let syncRecord =
                        SyncTable.shared.getRecord(
                            packageId: package.id
                        ) {

                        if syncRecord.conflict {

                            packagesWithConflict.insert(
                                package.id
                            )

                        } else if syncRecord.lastMod ==
                                    package.lastMod {

                            packagesNeedingUpdate.remove(
                                package.id
                            )

                            packagesWithConflict.remove(
                                package.id
                            )
                        }
                    }

                    print(
                        "🎉 Package synchronization completed"
                    )

                } else {

                    print(
                        "❌ Package synchronization failed"
                    )
                }
            }
        }
    }

    // MARK: - Format Date

    // Server lastMod is Unix milliseconds.

    private func formattedDate(
        from unixTimestamp: Int64
    ) -> String {

        let date =
            Date(
                timeIntervalSince1970:
                    TimeInterval(unixTimestamp) / 1000
            )

        let formatter =
            DateFormatter()

        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(
            from: date
        )
    }
}

// MARK: - Preview

#Preview {

    HomeView {

        print(
            "User signed out"
        )
    }
}
