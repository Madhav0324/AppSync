
import Foundation

// MARK: - Request Models

struct DownloadRequest: Codable {

    let packages: [DownloadPackage]
}

struct DownloadPackage: Codable {

    let packageId: String
    let files: [String]
}

// MARK: - Response Models

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

// MARK: - Download API

class DownloadApiClass {

    static let shared = DownloadApiClass()

    private init() {}

    private let downloadURL = URL(
        string: "https://j21sih3zdd.execute-api.eu-north-1.amazonaws.com/download"
    )!

    // MARK: - Get Download URL

    func getDownloadURL(
        packageId: String,
        fileId: String
    ) async -> String? {

        // Get authentication token

        guard let token = AuthManager.shared.getToken() else {

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

            // Convert Swift object → JSON

            let jsonData =
                try JSONEncoder().encode(requestBody)

            // Create HTTP request

            var request =
                URLRequest(url: downloadURL)

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

            // Send request to backend

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            // Check HTTP response

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print("❌ Invalid API response")

                return nil
            }

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ API request failed with status:",
                    httpResponse.statusCode
                )

                return nil
            }

            // Convert JSON → Swift object

            let downloadResponse =
                try JSONDecoder().decode(
                    DownloadResponse.self,
                    from: data
                )

            // Get the first package

            guard let downloadedPackage =
                    downloadResponse.packages.first else {

                print("❌ No package returned")

                return nil
            }

            // Get the first file

            guard let downloadedFile =
                    downloadedPackage.files.first else {

                print("❌ No file returned")

                return nil
            }

            // Print the URL so we can verify it

            print(
                "🔗 Download URL returned by backend:"
            )

            print(
                downloadedFile.downloadUrl
            )

            // Return the secure download URL

            return downloadedFile.downloadUrl

        } catch {

            print(
                "❌ API error:",
                error.localizedDescription
            )

            return nil
        }
    }

    // MARK: - Download File

    func downloadFile(
        from downloadUrl: String,
        fileName: String
    ) async -> URL? {

        // Convert String → URL

        guard let url = URL(
            string: downloadUrl
        ) else {

            print("❌ Invalid download URL:")
            print(downloadUrl)

            return nil
        }

        // Make sure this is a web URL

        guard let scheme = url.scheme,
              scheme == "https" || scheme == "http" else {

            print(
                "❌ Download URL is not an HTTP/HTTPS URL:"
            )

            print(downloadUrl)

            print(
                "⚠️ The backend must return a presigned HTTPS URL."
            )

            return nil
        }

        do {

            // MARK: - Download File

            let (data, response) =
                try await URLSession.shared.data(
                    from: url
                )

            // Check HTTP response

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print(
                    "❌ Invalid file download response"
                )

                return nil
            }

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ File download failed."
                )

                print(
                    "HTTP Status:",
                    httpResponse.statusCode
                )

                return nil
            }

            print(
                "✅ File received from server"
            )

            print(
                "📦 Downloaded bytes:",
                data.count
            )

            // MARK: - Documents Directory

            let documentsDirectory =
                FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                )[0]

            // MARK: - Downloads Directory

            let downloadsDirectory =
                documentsDirectory.appendingPathComponent(
                    "Downloads",
                    isDirectory: true
                )

            // Create Downloads folder

            try FileManager.default.createDirectory(
                at: downloadsDirectory,
                withIntermediateDirectories: true
            )

            // MARK: - File Location

            let fileURL =
                downloadsDirectory.appendingPathComponent(
                    fileName
                )

            // Create parent directory if fileName
            // contains folders.

            let parentDirectory =
                fileURL.deletingLastPathComponent()

            try FileManager.default.createDirectory(
                at: parentDirectory,
                withIntermediateDirectories: true
            )

            // Remove existing file

            if FileManager.default.fileExists(
                atPath: fileURL.path
            ) {

                try FileManager.default.removeItem(
                    at: fileURL
                )
            }

            // Save downloaded data

            try data.write(
                to: fileURL
            )

            // MARK: - Success

            print(
                "✅ File downloaded successfully"
            )

            print(
                "📍 File stored at:"
            )

            print(
                fileURL.path
            )

            return fileURL

        } catch {

            print(
                "❌ Download error:"
            )

            print(
                error.localizedDescription
            )

            return nil
        }
    }
}

