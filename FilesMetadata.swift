import Foundation

// MARK: - Package Manifest Models

struct PackageManifestResponse: Codable {
    let files: [PackageFile]
}

struct PackageFile: Codable {
    let id: String
    let path: String?
    let lastMod: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case path
        case lastMod = "last_mod"
    }
}


// MARK: - API Call Class

class PackageManifestApiClass {

    // MARK: - Singleton

    static let packageManifestObject = PackageManifestApiClass()

    private init() {}


    // MARK: - API Configuration

    private let baseURL =
        "https://j21sih3zdd.execute-api.eu-north-1.amazonaws.com/getpackagemanifest"


    // MARK: - Get Access Token

    private func getAccessToken() -> String? {
        return AuthManager.shared.getAccessToken()
    }


    // MARK: - Create URL Request

    private func createRequest(
        packageId: String
    ) -> URLRequest? {

        guard let accessToken = getAccessToken() else {
            print("❌ Access token not found")
            return nil
        }

        guard let url = URL(
            string: "\(baseURL)/\(packageId)"
        ) else {
            print("❌ Invalid package manifest URL")
            return nil
        }

        var request = URLRequest(url: url)

        request.httpMethod = "GET"

        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        return request
    }


    // MARK: - Get Package Manifest

    func getPackageManifest(
        packageId: String
    ) async -> [PackageFile]? {

        guard let request = createRequest(
            packageId: packageId
        ) else {
            return nil
        }

        do {

            // Send request to API Gateway
            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )


            // MARK: - HTTP Response

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print("❌ Invalid response from API Gateway")
                return nil
            }


            // MARK: - Check Status Code

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ Package manifest request failed. Status code:",
                    httpResponse.statusCode
                )

                if let errorResponse = String(
                    data: data,
                    encoding: .utf8
                ) {

                    print("API response:")
                    print(errorResponse)
                }

                return nil
            }


            // MARK: - Decode JSON

            let decoder = JSONDecoder()

            let manifestResponse =
                try decoder.decode(
                    PackageManifestResponse.self,
                    from: data
                )


            // MARK: - Return Files

            print(
                "✅ Received \(manifestResponse.files.count) files"
            )

            return manifestResponse.files

        } catch {

            print(
                "❌ Failed to get package manifest:",
                error.localizedDescription
            )

            return nil
        }
    }


    // MARK: - Local Package Last Modified

    private func getLocalPackageLastModified(
        package: Package
    ) -> Int64? {

        guard let packagePath = package.path else {
            print("❌ Package has no local path:", package.id)
            return nil
        }

        let documentsDirectory =
            FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

        let packageURL =
            documentsDirectory
                .appendingPathComponent("Packages")
                .appendingPathComponent(packagePath)


        guard FileManager.default.fileExists(
            atPath: packageURL.path
        ) else {

            print(
                "📦 Package does not exist locally:",
                packagePath
            )

            return nil
        }


        do {

            let attributes =
                try FileManager.default.attributesOfItem(
                    atPath: packageURL.path
                )

            guard let modificationDate =
                    attributes[.modificationDate] as? Date else {

                print(
                    "❌ Could not get local modification date:",
                    packagePath
                )

                return nil
            }


            // Convert local Date to Unix timestamp
            let unixTimestamp =
                Int64(modificationDate.timeIntervalSince1970)

            return unixTimestamp

        } catch {

            print(
                "❌ Failed to get local package metadata:",
                error.localizedDescription
            )

            return nil
        }
    }


    // MARK: - Check Package For Updates

    func packageNeedsDownload(
        package: Package
    ) -> Bool {

        guard let localLastModified =
                getLocalPackageLastModified(
                    package: package
                ) else {

            // Package doesn't exist locally.
            // Therefore it needs its first download.
            return true
        }


        let serverLastModified =
            package.lastMod


        print("📦 Package:", package.path ?? package.id)
        print("🌐 Server lastMod:", serverLastModified)
        print("💻 Local lastMod:", localLastModified)


        if serverLastModified != localLastModified {

            print("⬇️ Package needs download")

            return true

        } else {

            print("✅ Package is up to date")

            return false
        }
    }


    // MARK: - Check All Packages For Updates

    func packagesNeedingDownload(
        packages: [Package]
    ) -> Set<String> {

        var packagesNeedingDownload = Set<String>()


        for package in packages {

            if packageNeedsDownload(
                package: package
            ) {

                packagesNeedingDownload.insert(
                    package.id
                )
            }
        }


        return packagesNeedingDownload
    }
}
