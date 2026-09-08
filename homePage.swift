import SwiftUI
import Combine

struct HomeView: View {

    @State private var downloadedPackageIds: Set<String> = []
    let refreshTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    // MARK: - Package Data

    @State private var packages: [Package] = []

    // MARK: - UI State

    @State private var showPackages = false
    @State private var isLoading = false

    // MARK: - Selected Package

    @State private var selectedPackageId = ""
    @State private var selectedPackageName = ""
    @State private var selectedFiles: [PackageFile] = []

    // MARK: - Downloading Packages

    @State private var downloadingPackageIds: Set<String> = []

    // MARK: - Navigation

    @State private var showHomeView2 = false
    @State private var isLoadingManifest = false

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

                        // MARK: - Top Navigation Bar

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

                            // MARK: - Sign Out Button

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
                                            
                                            // CHECK FOR TICK MARKS IMMEDIATELY AFTER LOADING
                                            checkDownloadedPackages()

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
                                                    .system(
                                                        size: 20
                                                    )
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
                                                        .system(
                                                            size: 13
                                                        )
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
                                                    .system(
                                                        size: 13
                                                    )
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
                                                    .system(
                                                        size: 13
                                                    )
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

                                        // Navigate to HomeView2
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            openPackage(
                                                package
                                            )
                                        }

                                        // MARK: - Download Button

                                        Button {

                                            downloadPackage(
                                                packageId: package.id
                                            )

                                        } label: {

                                            if downloadingPackageIds
                                                .contains(package.id) {

                                                ProgressView()
                                                    .tint(.white)

                                            } else if downloadedPackageIds
                                                .contains(package.id) {

                                                Image(
                                                    systemName:
                                                        "checkmark.circle.fill"
                                                )
                                                .font(
                                                    .system(
                                                        size: 22
                                                    )
                                                )
                                                .foregroundStyle(.green)

                                            } else {

                                                Image(
                                                    systemName:
                                                        "arrow.down.circle"
                                                )
                                                .font(
                                                    .system(
                                                        size: 22
                                                    )
                                                )
                                                .foregroundStyle(
                                                    .white.opacity(0.8)
                                                )
                                            }
                                        }
                                        .frame(
                                            width: 55,
                                            height: 55
                                        )
                                        .buttonStyle(.plain)

                                        .disabled(
                                            downloadingPackageIds
                                                .contains(package.id)
                                            ||
                                            downloadedPackageIds
                                                .contains(package.id)
                                        )
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

            // MARK: - Navigation to HomeView2

            .navigationDestination(
                isPresented: $showHomeView2
            ) {

                HomeView2(
                    packageId: selectedPackageId,
                    packageName: selectedPackageName,
                    files: selectedFiles
                )
            }
        }

        // MARK: - Lifecycle Hooks

        .onAppear {
            username = AuthManager.shared.getUsername() ?? "Unknown User"
            checkDownloadedPackages()
        }
        .onReceive(refreshTimer) { _ in
            checkDownloadedPackages()
        }
    }

    // MARK: - Open Package

    private func openPackage(
        _ package: Package
    ) {

        selectedPackageId = package.id
        isLoadingManifest = true

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
                        package.path
                        ?? "Unknown Package"

                    selectedFiles = files

                    print(
                        "✅ Received \(files.count) files"
                    )

                    showHomeView2 = true

                } else {

                    print(
                        "❌ Failed to get package manifest"
                    )
                }

                isLoadingManifest = false
            }
        }
    }

    // MARK: - Download Complete Package

    private func downloadPackage(
        packageId: String
    ) {

        guard !downloadingPackageIds.contains(
            packageId
        ) else {
            return
        }

        downloadingPackageIds.insert(
            packageId
        )

        Task {

            let files =
                await PackageManifestApiClass
                    .packageManifestObject
                    .getPackageManifest(
                        packageId: packageId
                    )

            guard let files else {

                print(
                    "❌ Failed to get package manifest for download"
                )

                await MainActor.run {

                    downloadingPackageIds.remove(
                        packageId
                    )
                }

                return
            }

            print(
                "📦 Package contains \(files.count) files"
            )

            let success =
                await DownloadApiClass
                    .downloadApiObject
                    .downloadPackage(
                        packageId: packageId,
                        files: files
                    )

            await MainActor.run {

                downloadingPackageIds.remove(
                    packageId
                )

                if success {

                    downloadedPackageIds.insert(
                        packageId
                    )

                    print(
                        "✅ COMPLETE PACKAGE DOWNLOADED: \(packageId)"
                    )

                } else {

                    print(
                        "❌ PACKAGE DOWNLOAD FAILED: \(packageId)"
                    )
                }
            }
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
    
    // MARK: - Check Local Storage
    
    private func checkDownloadedPackages() {
        var newlyFound: Set<String> = []
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for package in packages {
            // Check if downloaded via DownloadApiClass
            let isFolderDownloaded = DownloadApiClass.downloadApiObject.isPackageDownloaded(packageId: package.id)
            
            // Check if downloaded as zip
            let rawPath = package.path ?? "notebook_v1"
            let safeZipName = rawPath.replacingOccurrences(of: "/", with: "-") + ".zip"
            let isZipDownloaded = FileManager.default.fileExists(atPath: documentsDirectory.appendingPathComponent(safeZipName).path)
            
            if isFolderDownloaded || isZipDownloaded {
                newlyFound.insert(package.id)
            }
        }
        
        if downloadedPackageIds != newlyFound {
            downloadedPackageIds = newlyFound
        }
    }
}


// MARK: - Preview

#Preview {

    HomeView(
        onSignOut: {
            print("User signed out")
        }
    )
}
