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
}

