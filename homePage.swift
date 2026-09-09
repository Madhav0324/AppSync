import SwiftUI

struct HomeView: View {

    // MARK: - Package Data

    @State private var packages: [Package] = []

    // MARK: - UI State

    @State private var showPackages = false
    @State private var isLoading = false

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
                                    systemName: "shippingbox"
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
                                            }
                                        }
                                        .padding(18)
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {

                                            openPackage(package)
                                        }

                                        // MARK: - Download Button

                                        Button {

                                            downloadPackage(
                                                package: package
                                            )

                                        } label: {

                                            Image(
                                                systemName:
                                                    "arrow.down.circle"
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

            // MARK: - Refresh Token Button

            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        Task {
                            await refreshTokens()
                        }

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

    // MARK: - Load Packages

    private func loadPackages() {

        isLoading = true

        Task {

            let receivedPackages =
                await ApiCallClass
                    .apicallobject
                    .getAllPackageMetadata()

            await MainActor.run {

                if let receivedPackages {

                    packages = receivedPackages
                    showPackages = true

                    print(
                        "✅ Received \(receivedPackages.count) packages"
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

    // MARK: - Refresh Cognito Token

    private func refreshTokens() async {

        let success =
            await AuthManager.shared.refreshToken()

        await MainActor.run {

            if success {

                print(
                    "🔄 Token refreshed successfully"
                )

            } else {

                print(
                    "❌ Could not refresh token"
                )
            }
        }
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

            // Get the files inside the package.

            let files =
                await PackageManifestApiClass
                    .packageManifestObject
                    .getPackageManifest(
                        packageId: package.id
                    )

            guard let files else {

                print(
                    "❌ Failed to get package manifest for download"
                )

                return
            }

            print(
                "📦 Package contains \(files.count) files"
            )

            // Download each file.

            for file in files {

                // Step 1:
                // Ask backend for the secure download URL.

                guard let downloadURL =
                        await DownloadApiClass
                            .shared
                            .getDownloadURL(
                                packageId: package.id,
                                fileId: file.id
                            )
                else {

                    print(
                        "❌ Could not get download URL for \(file.id)"
                    )

                    continue
                }

                print(
                    "🔗 Got download URL for \(file.id)"
                )

                // Step 2:
                // Download the file and save it locally.

                guard let fileURL =
                        await DownloadApiClass
                            .shared
                            .downloadFile(
                                from: downloadURL,
                                fileName: file.path ?? file.id
                            )
                else {

                    print(
                        "❌ Failed to download \(file.id)"
                    )

                    continue
                }

                // Step 3:
                // fileURL tells us where the file was saved.

                print(
                    "✅ Downloaded \(file.id)"
                )

                print(
                    "📍 Saved at: \(fileURL.path)"
                )
            }

            print(
                "✅ Package download process completed"
            )
        }
    }

    // MARK: - Format Date

    private func formattedDate(
        from milliseconds: Int64
    ) -> String {

        let date =
            Date(
                timeIntervalSince1970:
                    TimeInterval(milliseconds) / 1000
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
