import SwiftUI
import Combine

struct HomeView2: View {

    // MARK: - Package Information

    let packageId: String
    let packageName: String
    let files: [PackageFile]

    // MARK: - UI State

    @State private var showDownloadSuccess = false
    @State private var downloadedFileIds: Set<String> = []
    
    let refreshTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {

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

            // MARK: - Content

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    // MARK: - Package Name

                    Text(packageName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(files.count) files")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.6))

                    // MARK: - File List

                    VStack(spacing: 12) {

                        ForEach(files, id: \.id) { file in

                            FileRow(
                                file: file,
                                isDownloaded: downloadedFileIds.contains(file.id)
                            ) {
                                print("Selected file:")
                                print("Package ID:", packageId)
                                print("File ID:", file.id)
                                
                                if !downloadedFileIds.contains(file.id) {
                                    Task {
                                        await downloadFile(file: file)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 30)
            }
        }
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Download Successful", isPresented: $showDownloadSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The file has been downloaded successfully.")
        }
        
        // MARK: - Lifecycle
        
        .onAppear {
            checkDownloadedFiles()
        }
        .onReceive(refreshTimer) { _ in
            checkDownloadedFiles()
        }
    }
    
    // MARK: - Check Local Storage
    
    private func checkDownloadedFiles() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Use a temporary local set to prevent SwiftUI UI-update failures
        var newlyFoundDownloads = Set<String>()
        
        // 1. Check if ENTIRE package was downloaded via DownloadApiClass
        let isPackageFolderDownloaded = DownloadApiClass.downloadApiObject.isPackageDownloaded(packageId: packageId)
        
        // 2. Check if ENTIRE package was downloaded via HomeView (zip file)
        let safeZipName = packageName.replacingOccurrences(of: "/", with: "-") + ".zip"
        let isPackageZipDownloaded = FileManager.default.fileExists(atPath: documentsDirectory.appendingPathComponent(safeZipName).path)
        
        let isWholePackageDownloaded = isPackageFolderDownloaded || isPackageZipDownloaded
        
        // Uncomment these prints if you need to debug why it's failing to see the zip:
        // print("🔍 Checking Package: \(packageName)")
        // print("   Folder exists: \(isPackageFolderDownloaded)")
        // print("   Zip exists (\(safeZipName)): \(isPackageZipDownloaded)")
        
        for file in files {
            // If the whole package is downloaded, tick every file automatically
            if isWholePackageDownloaded {
                newlyFoundDownloads.insert(file.id)
                continue
            }
            
            let safeFileName = URL(fileURLWithPath: file.path ?? file.id).lastPathComponent
            
            let singleFilePath = documentsDirectory.appendingPathComponent(safeFileName).path
            let packageFilePath = documentsDirectory
                .appendingPathComponent("Packages")
                .appendingPathComponent(packageId)
                .appendingPathComponent(safeFileName)
                .path
                
            if FileManager.default.fileExists(atPath: singleFilePath) ||
               FileManager.default.fileExists(atPath: packageFilePath) {
                newlyFoundDownloads.insert(file.id)
            }
        }
        
        // Assign the complete list at once to force SwiftUI to redraw the checkmarks
        if downloadedFileIds != newlyFoundDownloads {
            downloadedFileIds = newlyFoundDownloads
        }
    }

    // MARK: - Download Single File

    private func downloadFile(file: PackageFile) async {

        print("📤 Starting download API request")

        let downloadedFile = await DownloadApiClass.downloadApiObject.getDownloadURL(
            packageId: packageId,
            fileId: file.id
        )

        guard let downloadedFile else {
            print("❌ Could not get download URL")
            return
        }

        let fileName = URL(fileURLWithPath: downloadedFile.path ?? file.path ?? file.id).lastPathComponent

        let savedURL = await DownloadApiClass.downloadApiObject.downloadFile(
            from: downloadedFile.downloadUrl,
            fileName: fileName
        )

        if let savedURL {
            print("✅ File successfully saved to: \(savedURL.path)")

            await MainActor.run {
                showDownloadSuccess = true
                downloadedFileIds.insert(file.id)
            }
        } else {
            print("❌ File download failed")
        }
    }
}

// MARK: - File Row View

struct FileRow: View {

    let file: PackageFile
    let isDownloaded: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {

                Image(systemName: "doc")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 5) {
                    Text(file.path ?? "Unknown File")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(file.id)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                    .foregroundStyle(isDownloaded ? .green : .white.opacity(0.7))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isDownloaded ? .green.opacity(0.15) : .white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isDownloaded ? .green.opacity(0.5) : .white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }
}
