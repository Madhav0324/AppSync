import Foundation

// MARK: - Download Request Models

struct DownloadRequest: Codable {

    // MARK: - CHANGED
    // The API expects an array called "packages".

    let packages: [DownloadPackage]
}

struct DownloadPackage: Codable {

    let packageId: String
    let files: [String]
}

// MARK: - Download Response Models

struct DownloadResponse: Codable {

    let packages: [DownloadedPackage]
}

struct DownloadedPackage: Codable {

    let packageId: String
    let files: [DownloadedFile]
}

struct DownloadedFile: Codable {

    let id: String
    let path: String?
    let downloadUrl: String
    let size: Int

    enum CodingKeys: String, CodingKey {

        case id
        case path
        case downloadUrl
        case size
    }
}

// MARK: - Download API Class

class DownloadApiClass {

    static let downloadApiObject = DownloadApiClass()

    private init() {}

    // MARK: - API URL

    private let downloadURL = URL(
        string: "https://j21sih3zdd.execute-api.eu-north-1.amazonaws.com/download"
    )!

    // MARK: - Get ID Token

    private func getToken() -> String? {

        return AuthManager.shared.getToken()
    }

    // MARK: - Get Download URL

    func getDownloadURL(
        packageId: String,
        fileId: String
    ) async -> DownloadedFile? {

        // Get JWT token

        guard let token = getToken() else {

            print("❌ ID token not found")
            return nil
        }

        // Create request body

        let requestBody = DownloadRequest(
            packages: [
                DownloadPackage(
                    packageId: packageId,
                    files: [fileId]
                )
            ]
        )

        do {

            // Convert request body to JSON

            let jsonData =
                try JSONEncoder().encode(
                    requestBody
                )

            // Create HTTP request

            var request =
                URLRequest(
                    url: downloadURL
                )

            request.httpMethod = "POST"

            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )

            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            request.httpBody = jsonData

            print("📤 Requesting download URL")
            print("Package:", packageId)
            print("File:", fileId)

            // Send request

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            // Check HTTP response

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print(
                    "❌ Invalid Download API response"
                )

                return nil
            }

            // Check status code

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ Download API failed:",
                    httpResponse.statusCode
                )

                if let error = String(
                    data: data,
                    encoding: .utf8
                ) {

                    print(error)
                }

                return nil
            }

            // Decode response

            let downloadResponse =
                try JSONDecoder().decode(
                    DownloadResponse.self,
                    from: data
                )

            // Get returned file

            guard let downloadedFile =
                    downloadResponse
                        .packages
                        .first?
                        .files
                        .first else {

                print(
                    "❌ No download file returned"
                )

                return nil
            }

            print(
                "✅ Download URL received"
            )

            return downloadedFile

        } catch {

            print(
                "❌ Download API error:",
                error.localizedDescription
            )

            return nil
        }
    }

    // MARK: - Download One File

    func downloadFile(
        from downloadUrl: String,
        fileName: String
    ) async -> URL? {

        // Convert the presigned URL into a URL.

        guard let url =
                URL(string: downloadUrl) else {

            print(
                "❌ Invalid download URL"
            )

            return nil
        }

        do {

            print(
                "⬇️ Downloading file:",
                fileName
            )

            // Download actual file from S3.

            let (data, response) =
                try await URLSession.shared.data(
                    from: url
                )

            // Check HTTP response.

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print(
                    "❌ Invalid S3 response"
                )

                return nil
            }

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ S3 download failed:",
                    httpResponse.statusCode
                )

                return nil
            }

            // Get Documents directory.

            let documentsDirectory =
                FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                )[0]

            // Make sure only the filename is used.

            let safeFileName =
                URL(
                    fileURLWithPath: fileName
                )
                .lastPathComponent

            // Create destination URL.

            let fileURL =
                documentsDirectory
                    .appendingPathComponent(
                        safeFileName
                    )

            // Remove old file if it exists.

            if FileManager.default.fileExists(
                atPath: fileURL.path
            ) {

                try FileManager.default.removeItem(
                    at: fileURL
                )
            }

            // Save file.

            try data.write(
                to: fileURL
            )

            print(
                "✅ File successfully saved"
            )

            print(
                "📁 Location:",
                fileURL.path
            )

            return fileURL

        } catch {

            print(
                "❌ Failed to download file:",
                error.localizedDescription
            )

            return nil
        }
    }

    // MARK: - CHANGED:
    // Check If Package Is Downloaded

    func isPackageDownloaded(
        packageId: String
    ) -> Bool {

        // Get Documents directory.

        let documentsDirectory =
            FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

        // Build:
        //
        // Documents/Packages/<packageId>

        let packageDirectory =
            documentsDirectory
                .appendingPathComponent(
                    "Packages",
                    isDirectory: true
                )
                .appendingPathComponent(
                    packageId,
                    isDirectory: true
                )

        // Check whether the package directory exists.

        let exists =
            FileManager.default.fileExists(
                atPath: packageDirectory.path
            )

        print(
            "📦 Package \(packageId) downloaded:",
            exists
        )

        return exists
    }

    // MARK: - ADDED: Check If File Is Downloaded
    func isFileDownloaded(packageId: String, fileName: String) -> Bool {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        
        let safeFileName = URL(fileURLWithPath: fileName).lastPathComponent
        
        let fileURL = documentsDirectory
            .appendingPathComponent("Packages", isDirectory: true)
            .appendingPathComponent(packageId, isDirectory: true)
            .appendingPathComponent(safeFileName)
            
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // MARK: - Download Entire Package

    func downloadPackage(
        packageId: String,
        files: [PackageFile]
    ) async -> Bool {

        guard !files.isEmpty else {

            print(
                "❌ Package contains no files"
            )

            return false
        }

        print("")
        print(
            "📦 Starting package download"
        )

        print(
            "Package ID:",
            packageId
        )

        print(
            "Files:",
            files.count
        )

        // MARK: - Temporary Staging Storage

        let cachesDirectory =
            FileManager.default.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            )[0]

        let stagingDirectory =
            cachesDirectory
                .appendingPathComponent(
                    "Staging",
                    isDirectory: true
                )
                .appendingPathComponent(
                    packageId,
                    isDirectory: true
                )

        do {

            // Create staging directory.

            try FileManager.default.createDirectory(
                at: stagingDirectory,
                withIntermediateDirectories: true
            )

            print(
                "📂 Staging:",
                stagingDirectory.path
            )

            // MARK: - Download Every File

            for file in files {

                print("")

                print(
                    "⬇️ Downloading file:",
                    file.id
                )

                // Get presigned S3 URL.

                guard let downloadedFile =
                        await getDownloadURL(
                            packageId: packageId,
                            fileId: file.id
                        ) else {

                    print(
                        "❌ Could not get download URL"
                    )

                    // Delete incomplete package.

                    try? FileManager.default.removeItem(
                        at: stagingDirectory
                    )

                    return false
                }

                // Get only the filename.

                let fileName =
                    URL(
                        fileURLWithPath:
                            downloadedFile.path
                            ?? file.path
                            ?? file.id
                    )
                    .lastPathComponent

                // Download actual file into staging.

                guard await downloadFileToStaging(
                    from: downloadedFile.downloadUrl,
                    fileName: fileName,
                    stagingDirectory: stagingDirectory
                ) != nil else {

                    print(
                        "❌ Failed to download:",
                        fileName
                    )

                    // Delete incomplete package.

                    try? FileManager.default.removeItem(
                        at: stagingDirectory
                    )

                    return false
                }

                print(
                    "✅ Staged:",
                    fileName
                )
            }

            // MARK: - Move Complete Package

            print("")

            print(
                "✅ All files downloaded"
            )

            print(
                "📦 Moving package to permanent storage"
            )

            // Get Documents directory.

            let documentsDirectory =
                FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                )[0]

            // Create Packages directory.

            let packagesDirectory =
                documentsDirectory
                    .appendingPathComponent(
                        "Packages",
                        isDirectory: true
                    )

            try FileManager.default.createDirectory(
                at: packagesDirectory,
                withIntermediateDirectories: true
            )

            // Create final package directory.

            let finalPackageDirectory =
                packagesDirectory
                    .appendingPathComponent(
                        packageId,
                        isDirectory: true
                    )

            // Remove old package if it exists.

            if FileManager.default.fileExists(
                atPath: finalPackageDirectory.path
            ) {

                try FileManager.default.removeItem(
                    at: finalPackageDirectory
                )
            }

            // Move complete package from staging
            // into permanent storage.

            try FileManager.default.moveItem(
                at: stagingDirectory,
                to: finalPackageDirectory
            )

            print(
                "🎉 Package download complete"
            )

            print(
                "📁 Saved at:",
                finalPackageDirectory.path
            )

            // ADDED: Simple broadcast notification using a raw String
            NotificationCenter.default.post(
                name: Notification.Name("PackageDownloadedNotification"),
                object: nil,
                userInfo: ["packageId": packageId]
            )

            return true

        } catch {

            print(
                "❌ Package download failed:",
                error.localizedDescription
            )

            // Clean up staging.

            try? FileManager.default.removeItem(
                at: stagingDirectory
            )

            return false
        }
    }

    // MARK: - Download One File Into Staging

    private func downloadFileToStaging(
        from downloadUrl: String,
        fileName: String,
        stagingDirectory: URL
    ) async -> URL? {

        guard let url =
                URL(string: downloadUrl) else {

            print(
                "❌ Invalid download URL"
            )

            return nil
        }

        do {

            print(
                "⬇️ Downloading:",
                fileName
            )

            // Download file from S3.

            let (data, response) =
                try await URLSession.shared.data(
                    from: url
                )

            // Check response.

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print(
                    "❌ Invalid S3 response"
                )

                return nil
            }

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ S3 download failed:",
                    httpResponse.statusCode
                )

                return nil
            }

            // Make sure only filename is used.

            let safeFileName =
                URL(
                    fileURLWithPath: fileName
                )
                .lastPathComponent

            // Create staging file URL.

            let fileURL =
                stagingDirectory
                    .appendingPathComponent(
                        safeFileName
                    )

            // Save file into staging.

            try data.write(
                to: fileURL
            )

            return fileURL

        } catch {

            print(
                "❌ Failed to save file:",
                error.localizedDescription
            )

            return nil
        }
    }
}
