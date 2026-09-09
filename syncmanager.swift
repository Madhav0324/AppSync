//import Foundation
//
//struct ServerMetadata {
//    let id: String
//    let lastMod: Int64
//}
//
//class SyncManager {
//
////    static let shared = SyncManager()
//
//    private init() {}
//
//    // MARK: - Check If Download Is Required
//
//    private func requiresDownload(
//        clientLastMod: Int64?,
//        syncLastMod: Int64?,
//        serverLastMod: Int64
//    ) -> Bool {
//
//        guard let client = clientLastMod,
//              let sync = syncLastMod else {
//            return true
//        }
//
//        return client == sync && serverLastMod > sync
//    }
//
//    // MARK: - Compare Files And Download
//
//    func compareFilesAndDownload(
//        packageId: String,
//        packagePath: String,
//        serverFiles: [ServerMetadata]
//    ) async {
//
//        let syncRecords =
//            DatabaseService.shared.getSyncRecords(
//                for: packageId
//            )
//
//        var filesToDownload: [ServerMetadata] = []
//
//        for serverFile in serverFiles {
//
//            let clientLastMod =
//                getLocalLastMod(
//                    for: serverFile.id,
//                    packagePath: packagePath
//                )
//
//            let syncRecord =
//                syncRecords.first {
//                    $0.name == serverFile.id
//                }
//
//            if requiresDownload(
//                clientLastMod: clientLastMod,
//                syncLastMod: syncRecord?.lastMod,
//                serverLastMod: serverFile.lastMod
//            ) {
//
//                filesToDownload.append(
//                    serverFile
//                )
//            }
//        }
//
//        for file in filesToDownload {
//
//            await executeFileDownload(
//                packageId: packageId,
//                packagePath: packagePath,
//                file: file
//            )
//        }
//    }
//
//    // MARK: - Download File
//
//    private func executeFileDownload(
//        packageId: String,
//        packagePath: String,
//        file: ServerMetadata
//    ) async {
//
//        guard let downloadedFile =
//            await DownloadApiClass
//                .downloadApiObject
//                .getDownloadURL(
//                    packageId: packageId,
//                    fileId: file.id
//                )
//        else {
//
//            print(
//                "❌ Could not get download URL for \(file.id)"
//            )
//
//            return
//        }
//
//        // Keep the complete path from metadata.
//        //
//        // Example:
//        //
//        // pages/page1
//
//        let filePath =
//            downloadedFile.path ?? file.id
//
//        print("📦 Package ID:")
//        print(packageId)
//
//        print("📁 Package path:")
//        print(packagePath)
//
//        print("📄 File ID:")
//        print(file.id)
//
//        print("📄 File path:")
//        print(filePath)
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
//        if savedURL != nil {
//
//            print(
//                "✅ File successfully downloaded:"
//            )
//
//            print(
//                savedURL!.path
//            )
//
//            // Save sync information using FILE ID.
//            //
//            // The ID is still used for database/API identity.
//            // It is NOT used as the local filename.
//
//            DatabaseService.shared.upsertSyncRecord(
//                name: file.id,
//                packageId: packageId,
//                lastMod: file.lastMod
//            )
//        }
//    }
//
//    // MARK: - Get Local Modification Date
//
//    private func getLocalLastMod(
//        for fileId: String,
//        packagePath: String
//    ) -> Int64? {
//
//        let fileManager =
//            FileManager.default
//
//        let documentsDirectory =
//            fileManager.urls(
//                for: .documentDirectory,
//                in: .userDomainMask
//            )[0]
//
//        // We need the actual file path.
//        //
//        // Since SyncManager only has fileId here,
//        // we cannot know pages/page1 if fileId is different.
//        //
//        // Return nil so the sync logic will download it
//        // when there is no local record.
//
//        let fileURL =
//            documentsDirectory
//                .appendingPathComponent(
//                    "Packages",
//                    isDirectory: true
//                )
//                .appendingPathComponent(
//                    packagePath,
//                    isDirectory: true
//                )
//                .appendingPathComponent(
//                    fileId
//                )
//
//        guard fileManager.fileExists(
//            atPath: fileURL.path
//        ) else {
//
//            return nil
//        }
//
//        if let attributes =
//            try? fileManager.attributesOfItem(
//                atPath: fileURL.path
//            ),
//           let modificationDate =
//                attributes[.modificationDate] as? Date {
//
//            return Int64(
//                modificationDate.timeIntervalSince1970 * 1000
//            )
//        }
//
//        return nil
//    }
//}
