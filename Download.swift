import Foundation

// MARK: - Download Request Models

struct DownloadRequest: Codable {
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
}

// MARK: - Download Manager

final class DownloadApiClass {

    static let shared = DownloadApiClass()

    private init() {}

    // MARK: - API Gateway URL

    private let downloadURL = URL(
        string: "https://j21sih3zdd.execute-api.eu-north-1.amazonaws.com/download"
    )!

    // MARK: - Local Storage

    private var packagesDirectory: URL {

        let documentsDirectory =
            FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

        return documentsDirectory.appendingPathComponent(
            "Packages",
            isDirectory: true
        )
    }

    // MARK: - Temporary Staging

    private var stagingDirectory: URL {

        let documentsDirectory =
            FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

        return documentsDirectory.appendingPathComponent(
            "DownloadStaging",
            isDirectory: true
        )
    }

    // MARK: - Download Package

    func downloadPackage(
        package: Package
    ) async -> Bool {

        print("")
        print("📦 Starting package synchronization")
        print("Package ID:", package.id)
        print("Package path:", package.path ?? "nil")

        // ------------------------------------------------
        // STEP 1 - Validate package path
        // ------------------------------------------------

        guard let packagePath = package.path else {

            print("❌ Package does not have a path")

            return false
        }

        // ------------------------------------------------
        // STEP 2 - Find local package
        // ------------------------------------------------

        let localPackageDirectory =
            packagesDirectory.appendingPathComponent(
                sanitizedRelativePath(packagePath),
                isDirectory: true
            )

        print("")
        print("📁 LOCAL PACKAGE DIRECTORY")
        print(localPackageDirectory.path)
        print("")

        let packageExists =
            FileManager.default.fileExists(
                atPath: localPackageDirectory.path
            )

        // ------------------------------------------------
        // STEP 3 - Get SyncTable record
        // ------------------------------------------------

        let syncRecord =
            SyncTable.shared.getRecord(
                packageId: package.id
            )

        // ------------------------------------------------
        // STEP 4 - Get server manifest
        // ------------------------------------------------

        guard let files =
                await PackageManifestApiClass
                    .packageManifestObject
                    .getPackageManifest(
                        packageId: package.id
                    )
        else {

            print("❌ Could not get package manifest")

            return false
        }

        // ------------------------------------------------
        // STEP 5 - First-time synchronization
        // ------------------------------------------------

        guard packageExists,
              syncRecord != nil
        else {

            print("🆕 Package has not been synchronized before")
            print("⬇️ Downloading all files")

            return await downloadFiles(
                package: package,
                packagePath: packagePath,
                files: files,
                packageExists: packageExists,
                localPackageDirectory: localPackageDirectory
            )
        }

        // ------------------------------------------------
        // STEP 6 - Get local modification time
        // ------------------------------------------------

        guard let localLastMod =
                getLocalPackageLastModified(
                    at: localPackageDirectory
                )
        else {

            print("⚠️ Could not determine local modification time")
            print("⬇️ Downloading package")

            return await downloadFiles(
                package: package,
                packagePath: packagePath,
                files: files,
                packageExists: true,
                localPackageDirectory: localPackageDirectory
            )
        }

        // ------------------------------------------------
        // STEP 7 - Timestamp comparison
        // ------------------------------------------------

        let syncLastMod = syncRecord!.lastMod
        let serverLastMod = package.lastMod

        /*
         Filesystem timestamps have lower precision than
         the server timestamp.

         Local timestamp -> milliseconds derived from Date
         SyncTable        -> exact server milliseconds
         Server           -> exact server milliseconds

         For Local vs SyncTable we compare seconds.

         SyncTable itself continues to store the exact
         server millisecond timestamp.
         */

        let localSeconds = localLastMod / 1000
        let syncSeconds = syncLastMod / 1000

        print("")
        print("========== SYNC COMPARISON ==========")
        print("Package:", package.id)
        print("Local lastMod:", localLastMod)
        print("SyncTable lastMod:", syncLastMod)
        print("Server lastMod:", serverLastMod)
        print("-------------------------------------")
        print("Local seconds:", localSeconds)
        print("Sync seconds:", syncSeconds)
        print("=====================================")
        print("")

        // ------------------------------------------------
        // CASE 1
        //
        // Local == SyncTable < Server
        //
        // Server changed.
        // Local did not change.
        //
        // DOWNLOAD
        // ------------------------------------------------

        if localSeconds == syncSeconds &&
            syncLastMod < serverLastMod {

            print("⬇️ CASE 1")
            print("Local == SyncTable < Server")
            print("Server has newer data")
            print("⬇️ Download required")

            return await downloadFiles(
                package: package,
                packagePath: packagePath,
                files: files,
                packageExists: true,
                localPackageDirectory: localPackageDirectory
            )
        }

        // ------------------------------------------------
        // CASE 2
        //
        // Local == SyncTable == Server
        //
        // Everything synchronized.
        // ------------------------------------------------

        if localSeconds == syncSeconds &&
            syncLastMod == serverLastMod {

            print("✅ CASE 2")
            print("Local == SyncTable == Server")
            print("No changes required")

            return true
        }

        // ------------------------------------------------
        // CASE 3
        //
        // Local > SyncTable == Server
        //
        // Local changed.
        // Server did not change.
        //
        // UPLOAD NEEDED
        // ------------------------------------------------

        if localSeconds > syncSeconds &&
            syncLastMod == serverLastMod {

            print("⬆️ CASE 3")
            print("Local > SyncTable == Server")
            print("UPLOAD NEEDS TO BE DONE")
            print("Package:", package.id)

            return true
        }

        // ------------------------------------------------
        // CASE 4
        //
        // Local > SyncTable < Server
        //
        // Local changed.
        // Server changed.
        //
        // CONFLICT
        // ------------------------------------------------

        if localSeconds > syncSeconds &&
            syncLastMod < serverLastMod {

            print("⚠️ CASE 4")
            print("Local > SyncTable < Server")
            print("CONFLICT DETECTED")
            print("Package:", package.id)

            SyncTable.shared.updateConflict(
                packageId: package.id,
                conflict: true
            )

            return false
        }

        // ------------------------------------------------
        // CASE 5
        //
        // Local == SyncTable > Server
        //
        // Ignore.
        // ------------------------------------------------

        if localSeconds == syncSeconds &&
            syncLastMod > serverLastMod {

            print("ℹ️ CASE 5")
            print("Local == SyncTable > Server")
            print("Ignoring this case")

            return true
        }

        // ------------------------------------------------
        // FALLBACK
        // ------------------------------------------------

        print("⚠️ Unhandled synchronization state")
        print("Local:", localLastMod)
        print("SyncTable:", syncLastMod)
        print("Server:", serverLastMod)

        return false
    }

    // MARK: - Download Files

    private func downloadFiles(
        package: Package,
        packagePath: String,
        files: [PackageFile],
        packageExists: Bool,
        localPackageDirectory: URL
    ) async -> Bool {

        let operationID =
            UUID().uuidString

        let operationStagingDirectory =
            stagingDirectory.appendingPathComponent(
                operationID,
                isDirectory: true
            )

        // ------------------------------------------------
        // IMPORTANT
        //
        // packagePath might be:
        //
        // MyNotes/N5
        //
        // But staging must contain:
        //
        // UUID/N5
        //
        // NOT:
        //
        // UUID/MyNotes/N5
        // ------------------------------------------------

        let safePackagePath =
            sanitizedRelativePath(packagePath)

        let packageName =
            URL(
                fileURLWithPath: safePackagePath
            ).lastPathComponent

        let packageStagingDirectory =
            operationStagingDirectory.appendingPathComponent(
                packageName,
                isDirectory: true
            )

        do {

            // ------------------------------------------------
            // STEP 1 - Create staging operation directory
            // ------------------------------------------------

            try FileManager.default.createDirectory(
                at: operationStagingDirectory,
                withIntermediateDirectories: true
            )

            // ------------------------------------------------
            // STEP 2 - Prepare package in staging
            // ------------------------------------------------

            if packageExists {

                print("")
                print("📋 EXISTING PACKAGE")
                print("Copying ONLY package into staging")
                print("")
                print("FROM:")
                print(localPackageDirectory.path)
                print("")
                print("TO:")
                print(packageStagingDirectory.path)
                print("")

                try FileManager.default.copyItem(
                    at: localPackageDirectory,
                    to: packageStagingDirectory
                )

                print("✅ Existing package copied to staging")

            } else {

                print("")
                print("🆕 NEW PACKAGE")
                print("Creating package in staging")
                print("Package:", packageName)
                print("")

                try FileManager.default.createDirectory(
                    at: packageStagingDirectory,
                    withIntermediateDirectories: true
                )

                print("✅ Empty package created in staging")
            }

            // ------------------------------------------------
            // STEP 3 - Download files into staging
            // ------------------------------------------------

            for file in files {

                print("")
                print("⬇️ Downloading file:", file.id)
                print("Path:", file.path ?? "nil")

                guard let downloadedFile =
                        await getDownloadFile(
                            packageId: package.id,
                            fileId: file.id
                        )
                else {

                    print("❌ Could not get download information")
                    print("File:", file.id)

                    removeStagingDirectory(
                        operationStagingDirectory
                    )

                    return false
                }

                guard await downloadFileToStaging(
                    downloadedFile: downloadedFile,
                    expectedPath: file.path,
                    packageStagingDirectory:
                        packageStagingDirectory
                )
                else {

                    print("❌ File failed to download")
                    print("File:", file.id)

                    removeStagingDirectory(
                        operationStagingDirectory
                    )

                    return false
                }

                print(
                    "✅ File successfully updated in staging:",
                    file.id
                )
            }

            // ------------------------------------------------
            // STEP 4 - FINAL SERVER VERSION CHECK
            //
            // VERY IMPORTANT
            //
            // We downloaded everything using the server
            // version that was passed into this function.
            //
            // Before touching Main, ask the server again.
            // ------------------------------------------------

            print("")
            print("=====================================")
            print("🔍 FINAL SERVER VERSION CHECK")
            print("Package:", package.id)
            print(
                "Original server lastMod:",
                package.lastMod
            )
            print("=====================================")
            print("")

            guard let latestPackages =
                    await ApiCallClass
                        .apicallobject
                        .getAllPackageMetadata()
            else {

                print("❌ Could not get latest server metadata")
                print("🛑 Package promotion cancelled")
                print("🛑 Main package was NOT changed")

                removeStagingDirectory(
                    operationStagingDirectory
                )

                return false
            }

            guard let latestServerPackage =
                    latestPackages.first(
                        where: {
                            $0.id == package.id
                        }
                    )
            else {

                print("❌ Package no longer exists on server")
                print("🛑 Package promotion cancelled")
                print("🛑 Main package was NOT changed")

                removeStagingDirectory(
                    operationStagingDirectory
                )

                return false
            }

            print(
                "Latest server lastMod:",
                latestServerPackage.lastMod
            )

            // ------------------------------------------------
            // SERVER CHANGED DURING DOWNLOAD
            // ------------------------------------------------

            if latestServerPackage.lastMod != package.lastMod {

                print("")
                print("🚨🚨🚨 SERVER VERSION CHANGED 🚨🚨🚨")
                print("")
                print("Original server lastMod:")
                print(package.lastMod)
                print("")
                print("Latest server lastMod:")
                print(latestServerPackage.lastMod)
                print("")
                print(
                    "Someone modified/uploaded this package while it was downloading."
                )
                print("")
                print("🛑 DOWNLOAD CANCELLED")
                print("🛑 MAIN PACKAGE WAS NOT TOUCHED")
                print("🧹 STAGING PACKAGE WILL BE DELETED")
                print("")

                // Mark conflict.
                SyncTable.shared.updateConflict(
                    packageId: package.id,
                    conflict: true
                )

                removeStagingDirectory(
                    operationStagingDirectory
                )

                return false
            }

            // ------------------------------------------------
            // Server version is still the same.
            //
            // Safe to promote.
            // ------------------------------------------------

            print("")
            print("✅ FINAL SERVER VERSION CHECK PASSED")
            print(
                "Server lastMod is still:",
                package.lastMod
            )
            print("")
            print("🚚 Safe to promote package")
            print("")

            // ------------------------------------------------
            // STEP 5 - Promote COMPLETE package
            // ------------------------------------------------

            guard promoteCompletePackageToMainStorage(
                packagePath: packagePath,
                packageStagingDirectory:
                    packageStagingDirectory,
                operationStagingDirectory:
                    operationStagingDirectory
            )
            else {

                print(
                    "❌ Failed to promote complete package"
                )

                removeStagingDirectory(
                    operationStagingDirectory
                )

                return false
            }

            // ------------------------------------------------
            // STEP 6 - Update local modification dates
            // ------------------------------------------------

            let mainPackageDirectory =
                packagesDirectory.appendingPathComponent(
                    sanitizedRelativePath(packagePath),
                    isDirectory: true
                )

            for file in files {

                guard let filePath = file.path else {
                    continue
                }

                let localFileURL =
                    mainPackageDirectory.appendingPathComponent(
                        sanitizedRelativePath(filePath)
                    )

                guard FileManager.default.fileExists(
                    atPath: localFileURL.path
                ) else {
                    continue
                }

                setModificationDate(
                    at: localFileURL,
                    unixTimestampMilliseconds:
                        package.lastMod
                )
            }

            // ------------------------------------------------
            // STEP 7 - Update SyncTable
            // ------------------------------------------------

            SyncTable.shared.forceUpdateLastMod(
                packageId: package.id,
                serverLastMod: package.lastMod,
                name: package.path ?? package.id
            )

            // ------------------------------------------------
            // STEP 8 - Verify SyncTable
            // ------------------------------------------------

            guard let updatedSyncRecord =
                    SyncTable.shared.getRecord(
                        packageId: package.id
                    )
            else {

                print(
                    "❌ Download succeeded but SyncTable record was not found"
                )

                return false
            }

            guard updatedSyncRecord.lastMod ==
                    package.lastMod
            else {

                print(
                    "❌ SyncTable lastMod does not match server"
                )

                print(
                    "Expected:",
                    package.lastMod
                )

                print(
                    "Actual:",
                    updatedSyncRecord.lastMod
                )

                return false
            }

            print("")
            print(
                "💾 SyncTable lastMod updated from SERVER"
            )

            print(
                "Package:",
                package.id
            )

            print(
                "Server lastMod:",
                package.lastMod
            )

            print(
                "SyncTable lastMod:",
                updatedSyncRecord.lastMod
            )

            print(
                "conflict:",
                updatedSyncRecord.conflict
            )

            // ------------------------------------------------
            // STEP 9 - Remove staging
            // ------------------------------------------------

            removeStagingDirectory(
                operationStagingDirectory
            )

            print("")
            print(
                "🎉 Package synchronization completed"
            )
            print("")

            return true

        } catch {

            print("")
            print("❌ Package download error:")
            print(error.localizedDescription)

            removeStagingDirectory(
                operationStagingDirectory
            )

            return false
        }
    }

    // MARK: - Get Local Package Last Modified

    private func getLocalPackageLastModified(
        at packageDirectory: URL
    ) -> Int64? {

        guard let enumerator =
                FileManager.default.enumerator(
                    at: packageDirectory,
                    includingPropertiesForKeys: [
                        .contentModificationDateKey,
                        .isRegularFileKey
                    ]
                )
        else {
            return nil
        }

        var latestModificationDate: Date?

        for case let fileURL as URL in enumerator {

            guard let resourceValues =
                    try? fileURL.resourceValues(
                        forKeys: [
                            .contentModificationDateKey,
                            .isRegularFileKey
                        ]
                    )
            else {
                continue
            }

            // Only actual files.
            // Ignore directories.
            guard resourceValues.isRegularFile == true,
                  let modificationDate =
                    resourceValues.contentModificationDate
            else {
                continue
            }

            if latestModificationDate == nil ||
                modificationDate > latestModificationDate! {

                latestModificationDate =
                    modificationDate
            }
        }

        guard let latestModificationDate else {
            return nil
        }

        return Int64(
            latestModificationDate.timeIntervalSince1970 * 1000
        )
    }

    // MARK: - Set Modification Date

    private func setModificationDate(
        at url: URL,
        unixTimestampMilliseconds: Int64
    ) {

        let seconds =
            TimeInterval(unixTimestampMilliseconds) / 1000

        let date =
            Date(
                timeIntervalSince1970: seconds
            )

        do {

            try FileManager.default.setAttributes(
                [
                    .modificationDate: date
                ],
                ofItemAtPath: url.path
            )

            print("🕒 Local modification date updated")
            print("File:", url.path)

        } catch {

            print("⚠️ Could not set modification date")
            print(error.localizedDescription)
        }
    }

    // MARK: - Get Presigned URL

    private func getDownloadFile(
        packageId: String,
        fileId: String
    ) async -> DownloadedFile? {

        guard let token =
                AuthManager.shared.getToken()
        else {

            print("❌ Cognito ID token not found")

            return nil
        }

        let requestBody =
            DownloadRequest(
                packages: [
                    DownloadPackage(
                        packageId: packageId,
                        files: [fileId]
                    )
                ]
            )

        do {

            let jsonData =
                try JSONEncoder().encode(
                    requestBody
                )

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

            request.httpBody =
                jsonData

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            guard let httpResponse =
                    response as? HTTPURLResponse
            else {

                print("❌ Invalid API response")

                return nil
            }

            guard httpResponse.statusCode == 200
            else {

                print(
                    "❌ Download API failed:",
                    httpResponse.statusCode
                )

                return nil
            }

            let downloadResponse =
                try JSONDecoder().decode(
                    DownloadResponse.self,
                    from: data
                )

            guard let downloadedPackage =
                    downloadResponse.packages.first
            else {

                print("❌ Lambda returned no package")

                return nil
            }

            guard let downloadedFile =
                    downloadedPackage.files.first
            else {

                print("❌ Lambda returned no file")

                return nil
            }

            print("🔗 Presigned URL received")

            print(
                "File:",
                downloadedFile.id
            )

            print(
                "S3 path:",
                downloadedFile.path ?? "nil"
            )

            print(
                "Size:",
                downloadedFile.size
            )

            return downloadedFile

        } catch {

            print("❌ Download API error:")
            print(error.localizedDescription)

            return nil
        }
    }

    // MARK: - Download File Into Staging

    private func downloadFileToStaging(
        downloadedFile: DownloadedFile,
        expectedPath: String?,
        packageStagingDirectory: URL
    ) async -> Bool {

        guard let url =
                URL(
                    string: downloadedFile.downloadUrl
                )
        else {

            print("❌ Invalid presigned URL")

            return false
        }

        guard let scheme = url.scheme,
              scheme == "https" || scheme == "http"
        else {

            print(
                "❌ Download URL is not HTTP/HTTPS"
            )

            return false
        }

        do {

            let (temporaryURL, response) =
                try await URLSession.shared.download(
                    from: url
                )

            guard let httpResponse =
                    response as? HTTPURLResponse
            else {

                print("❌ Invalid S3 response")

                return false
            }

            guard httpResponse.statusCode == 200
            else {

                print(
                    "❌ S3 download failed:",
                    httpResponse.statusCode
                )

                return false
            }

            // File path is relative to the package itself.
            //
            // Example:
            //
            // package = N5
            // file path = pages/page.rtf
            //
            // Result:
            //
            // staging/UUID/N5/pages/page.rtf

            let relativePath =
                expectedPath
                ?? downloadedFile.path
                ?? downloadedFile.id

            let safeRelativePath =
                sanitizedRelativePath(
                    relativePath
                )

            let stagedFileURL =
                packageStagingDirectory.appendingPathComponent(
                    safeRelativePath
                )

            let parentDirectory =
                stagedFileURL.deletingLastPathComponent()

            try FileManager.default.createDirectory(
                at: parentDirectory,
                withIntermediateDirectories: true
            )

            // Replace existing file inside staging.

            if FileManager.default.fileExists(
                atPath: stagedFileURL.path
            ) {

                print(
                    "♻️ Replacing file INSIDE staging"
                )

                print(
                    stagedFileURL.path
                )

                try FileManager.default.removeItem(
                    at: stagedFileURL
                )
            }

            try FileManager.default.moveItem(
                at: temporaryURL,
                to: stagedFileURL
            )

            print("📦 File placed in staging:")
            print(stagedFileURL.path)

            return true

        } catch {

            print(
                "❌ S3 download/staging error:"
            )

            print(
                error.localizedDescription
            )

            return false
        }
    }

    // MARK: - Promote Complete Package

    private func promoteCompletePackageToMainStorage(
        packagePath: String,
        packageStagingDirectory: URL,
        operationStagingDirectory: URL
    ) -> Bool {

        let safePackagePath =
            sanitizedRelativePath(
                packagePath
            )

        let mainPackageDirectory =
            packagesDirectory.appendingPathComponent(
                safePackagePath,
                isDirectory: true
            )

        let backupRoot =
            operationStagingDirectory.appendingPathComponent(
                "OldPackageBackup",
                isDirectory: true
            )

        let backupPackageDirectory =
            backupRoot.appendingPathComponent(
                packageStagingDirectory.lastPathComponent,
                isDirectory: true
            )

        do {

            // ------------------------------------------------
            // Make sure Packages directory exists.
            // ------------------------------------------------

            try FileManager.default.createDirectory(
                at: packagesDirectory,
                withIntermediateDirectories: true
            )

            // ------------------------------------------------
            // Make sure Main package parent exists.
            // ------------------------------------------------

            try FileManager.default.createDirectory(
                at:
                    mainPackageDirectory
                        .deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            // ------------------------------------------------
            // Verify staging package exists.
            // ------------------------------------------------

            guard FileManager.default.fileExists(
                atPath: packageStagingDirectory.path
            )
            else {

                print(
                    "❌ Staging package does not exist"
                )

                print(
                    packageStagingDirectory.path
                )

                return false
            }

            // ------------------------------------------------
            // Move existing Main package to backup.
            // ------------------------------------------------

            if FileManager.default.fileExists(
                atPath: mainPackageDirectory.path
            ) {

                print("")
                print(
                    "📦 Moving old Main package to backup"
                )

                print(
                    "FROM:",
                    mainPackageDirectory.path
                )

                print(
                    "TO:",
                    backupPackageDirectory.path
                )

                try FileManager.default.createDirectory(
                    at: backupRoot,
                    withIntermediateDirectories: true
                )

                try FileManager.default.moveItem(
                    at: mainPackageDirectory,
                    to: backupPackageDirectory
                )

                print(
                    "✅ Old Main package backed up"
                )
            }

            // ------------------------------------------------
            // Move N5 from staging to Main.
            //
            // staging:
            //
            // DownloadStaging/UUID/N5
            //
            // becomes:
            //
            // Packages/MyNotes/N5
            // ------------------------------------------------

            print("")
            print(
                "🚚 Moving COMPLETE package to Main"
            )

            print(
                "FROM:",
                packageStagingDirectory.path
            )

            print(
                "TO:",
                mainPackageDirectory.path
            )

            do {

                try FileManager.default.moveItem(
                    at: packageStagingDirectory,
                    to: mainPackageDirectory
                )

                print("")
                print(
                    "✅ COMPLETE PACKAGE promoted to Main"
                )

            } catch {

                print("")
                print(
                    "❌ Could not move staging package to Main"
                )

                print(
                    error.localizedDescription
                )

                // Restore old package.

                if FileManager.default.fileExists(
                    atPath:
                        backupPackageDirectory.path
                ) {

                    print(
                        "♻️ Restoring old Main package"
                    )

                    try? FileManager.default.moveItem(
                        at: backupPackageDirectory,
                        to: mainPackageDirectory
                    )

                    print(
                        "✅ Old Main package restored"
                    )
                }

                return false
            }

            // ------------------------------------------------
            // New package is now in Main.
            // Delete backup.
            // ------------------------------------------------

            if FileManager.default.fileExists(
                atPath:
                    backupPackageDirectory.path
            ) {

                try FileManager.default.removeItem(
                    at: backupPackageDirectory
                )

                print(
                    "🧹 Old package backup removed"
                )
            }

            return true

        } catch {

            print("")
            print(
                "❌ Complete package promotion error:"
            )

            print(
                error.localizedDescription
            )

            // Emergency restore.

            if !FileManager.default.fileExists(
                atPath: mainPackageDirectory.path
            ),
            FileManager.default.fileExists(
                atPath:
                    backupPackageDirectory.path
            ) {

                print(
                    "♻️ Attempting to restore old Main package"
                )

                try? FileManager.default.moveItem(
                    at: backupPackageDirectory,
                    to: mainPackageDirectory
                )
            }

            return false
        }
    }

    // MARK: - Remove Staging

    private func removeStagingDirectory(
        _ operationStagingDirectory: URL
    ) {

        do {

            if FileManager.default.fileExists(
                atPath:
                    operationStagingDirectory.path
            ) {

                try FileManager.default.removeItem(
                    at: operationStagingDirectory
                )

                print(
                    "🧹 Staging area removed"
                )
            }

        } catch {

            print(
                "⚠️ Could not completely remove staging"
            )

            print(
                error.localizedDescription
            )
        }
    }

    // MARK: - Path Sanitization

    private func sanitizedRelativePath(
        _ path: String
    ) -> String {

        let components =
            path
                .split(separator: "/")
                .filter {
                    $0 != "." &&
                    $0 != ".."
                }

        return components.joined(
            separator: "/"
        )
    }
}
