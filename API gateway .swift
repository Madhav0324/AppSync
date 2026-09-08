import Foundation

// MARK: - API Response Models

struct PackageMetadataResponse: Codable {
    let packages: [Package]
}

struct Package: Codable {
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

class ApiCallClass {

    static let apicallobject = ApiCallClass()

    private init() {}

    // MARK: - API URL

    private let getAllPackageMetadataURL = URL(
        string: "https://j21sih3zdd.execute-api.eu-north-1.amazonaws.com/getallpackagemetadata"
    )!

    // MARK: - Get ID Token

    private func getToken() -> String? {
        return AuthManager.shared.getToken()
    }

    // MARK: - Create Request

    private func createRequest() -> URLRequest? {

        guard let token = getToken() else {
            print("❌ ID token not found")
            return nil
        }

        var request = URLRequest(
            url: getAllPackageMetadataURL
        )

        request.httpMethod = "GET"

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        return request
    }

    // MARK: - Get All Package Metadata

    func getAllPackageMetadata() async -> [Package]? {

        guard let request = createRequest() else {
            return nil
        }

        do {

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print("❌ Invalid response from API Gateway")
                return nil
            }

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ API request failed. Status code:",
                    httpResponse.statusCode
                )

                if let errorResponse =
                    String(
                        data: data,
                        encoding: .utf8
                    ) {

                    print("API response:")
                    print(errorResponse)
                }

                return nil
            }

            let decoder = JSONDecoder()

            let packageResponse =
                try decoder.decode(
                    PackageMetadataResponse.self,
                    from: data
                )

            print(
                "✅ Received \(packageResponse.packages.count) packages"
            )

            return packageResponse.packages

        } catch {

            print(
                "❌ Failed to get package metadata:",
                error.localizedDescription
            )

            return nil
        }
    }
}
