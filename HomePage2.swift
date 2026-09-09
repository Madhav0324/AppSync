import SwiftUI
import Combine

struct HomeView2: View {
    
    // MARK: - Package Information
    
    let packageId: String
    let packagePath: String
    let packageName: String
    let files: [PackageFile]
    
    // MARK: - UI State
    
    @State private var showDownloadSuccess = false
    @State private var downloadedFileIds: Set<String> = []
    @State private var selectedFileURL: URL?
    
    let refreshTimer = Timer.publish(
        every: 1.5,
        on: .main,
        in: .common
    ).autoconnect()
    
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
                        .font(
                            .system(
                                size: 28,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                    
                    Text("\(files.count) files")
                        .font(.system(size: 15))
                        .foregroundStyle(
                            .white.opacity(0.6)
                        )
                    
                    // MARK: - File List
                    
                    VStack(spacing: 12) {
                        
                        ForEach(
                            files,
                            id: \.id
                        ) { file in
                            
                            FileRow(
                                file: file,
                                isDownloaded:
                                    downloadedFileIds
                                    .contains(file.id)
                            ) {
                                
                                print("📄 Selected file")
                                print(
                                    "Package ID:",
                                    packageId
                                )
                                print(
                                    "Package Path:",
                                    packagePath
                                )
                                print(
                                    "File ID:",
                                    file.id
                                )
                                print(
                                    "File Path:",
                                    file.path ?? "No path"
                                )
                                
                                // MARK: - Already Downloaded
                                
                                if downloadedFileIds
                                    .contains(file.id) {
                                    
                                    if let localURL =
                                        getLocalFileURL(
                                            for: file
                                        ) {
                                        
                                        selectedFileURL =
                                        localURL
                                        
                                    } else {
                                        
                                        print(
                                            "❌ Local file not found"
                                        )
                                    }
                                    
                                } else {
                                    
                                    // MARK: - Download File
                                    
                                    Task {
                                        
                                        await downloadFile(
                                            file: file
                                        )
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
        
        // MARK: - Navigation
        
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        
        .navigationDestination(
            item: $selectedFileURL
        ) { fileURL in
            
            HomePage3(
                fileURL: fileURL
            )
        }
        
        // MARK: - Download Alert
        
        .alert(
            "Download Successful",
            isPresented: $showDownloadSuccess
        ) {
            
            Button(
                "OK",
                role: .cancel
            ) {}
            
        } message: {
            
            Text(
                "The file has been downloaded successfully."
            )
        }
        
        // MARK: - Lifecycle
        
        .onAppear {
            
            checkDownloadedFiles()
        }
        
        .onReceive(
            refreshTimer
        ) { _ in
            
            checkDownloadedFiles()
        }
    }
    
    // MARK: - Get Local File URL
    
    private func getLocalFileURL(
        for file: PackageFile
    ) -> URL? {
        
        guard let filePath = file.path else {
            
            print(
                "❌ File does not have a path"
            )
            
            return nil
        }
        
        let documentsDirectory =
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        
        // Documents/Packages/<packagePath>/<filePath>
        
        let fileURL =
        documentsDirectory
            .appendingPathComponent(
                "Packages",
                isDirectory: true
            )
            .appendingPathComponent(
                packagePath,
                isDirectory: true
            )
            .appendingPathComponent(
                filePath
            )
        
        print("🔎 Looking for file:")
        print(fileURL.path)
        
        if FileManager.default.fileExists(
            atPath: fileURL.path
        ) {
            
            print("✅ File found")
            
            return fileURL
            
        } else {
            
            print("❌ File not found")
            
            return nil
        }
    }
    
    // MARK: - Check Downloaded Files
    
    private func checkDownloadedFiles() {
        
        var newlyFoundDownloads =
        Set<String>()
        
        for file in files {
            
            guard let filePath =
                    file.path else {
                
                continue
            }
            
            let documentsDirectory =
            FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            
            // Documents/Packages/<packagePath>/<filePath>
            
            let fileURL =
            documentsDirectory
                .appendingPathComponent(
                    "Packages",
                    isDirectory: true
                )
                .appendingPathComponent(
                    packagePath,
                    isDirectory: true
                )
                .appendingPathComponent(
                    filePath
                )
            
            if FileManager.default.fileExists(
                atPath: fileURL.path
            ) {
                
                newlyFoundDownloads.insert(
                    file.id
                )
            }
        }
        
        if downloadedFileIds !=
            newlyFoundDownloads {
            
            downloadedFileIds =
            newlyFoundDownloads
        }
    }
    
    // MARK: - Download Single File
    
    private func downloadFile(
        file: PackageFile
    ) async {
        
        print(
            "📤 Starting download API request"
        )
        
        // Get download URL from server
        //
        //        let downloadedFile =
        //            await DownloadApiClass
        //                .downloadApiObject
        //                .getDownloadURL(
        //                    packageId: packageId,
        //                    fileId: file.id
        //                )
        
        //        guard let downloadedFile else {
        //
        //            print(
        //                "❌ Could not get download URL"
        //            )
        //
        //            return
    }
    
    // IMPORTANT:
    //
    // Use the path from metadata.
    //
    // Example:
    //
    // pages/page1
    //
    //        // Do NOT use file.id as the filename.
    //
    //        let filePath =
    //            downloadedFile.path
    //            ?? file.path
    //            ?? file.id
    //
    //        print(
    //            "📄 File path from metadata:"
    //        )
    //
    //        print(filePath)
    //
    //        // Download the actual file
    //
    //        let savedURL =
    //            await DownloadApiClass
    //                .downloadApiObject
    //                .downloadFile(
    //                    packagePath: packagePath,
    //                    from: downloadedFile.downloadUrl,
    //                    filePath: filePath
    //                )
    //
    //        if let savedURL {
    //
    //            print(
    //                "✅ File successfully saved:"
    //            )
    //
    //            print(
    //                savedURL.path
    //            )
    //
    //            await MainActor.run {
    //
    //                // Mark file as downloaded
    //
    //                downloadedFileIds.insert(
    //                    file.id
    //                )
    //
    //                // Show success message
    //
    //                showDownloadSuccess = true
    //
    //                // Open the downloaded file
    //
    //                selectedFileURL =
    //                    savedURL
    //            }
    //
    //        } else {
    //
    //            print(
    //                "❌ File download failed"
    //            )
    //        }
    //    }
    //}
    
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
                    
                    Image(
                        systemName: "doc"
                    )
                    .font(
                        .system(size: 20)
                    )
                    .foregroundStyle(.white)
                    
                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        
                        Text(
                            file.path
                            ?? "Unknown File"
                        )
                        .font(
                            .system(
                                size: 16,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        
                        Text(
                            file.id
                        )
                        .font(
                            .system(size: 12)
                        )
                        .foregroundStyle(
                            .white.opacity(0.5)
                        )
                        .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(
                        systemName:
                            isDownloaded
                        ? "checkmark.circle.fill"
                        : "arrow.down.circle"
                    )
                    .foregroundStyle(
                        isDownloaded
                        ? .green
                        : .white.opacity(0.7)
                    )
                }
                .padding()
                .frame(
                    maxWidth: .infinity
                )
                .background(
                    isDownloaded
                    ? .green.opacity(0.15)
                    : .white.opacity(0.08)
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 15
                    )
                    .stroke(
                        isDownloaded
                        ? .green.opacity(0.5)
                        : .white.opacity(0.12),
                        lineWidth: 1
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 15
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }
}
