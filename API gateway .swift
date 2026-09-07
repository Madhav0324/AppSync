
import Foundation

// MARK: - API Response Models

struct PackageMetadataResponse: Codable {
    let packages: [Package]
}

// FIX 1: Made properties optional. If the API misses a field, it won't throw the "data is missing" error.
struct Package: Codable {
    let id: String?
    let path: String?
    let lastMod: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case path
        case lastMod = "last_mod"
    }
}

// MARK: - Get Data

class GetData {

    private let getAllPackageMetadataURL =
        "https://j21sih3zdd.execute-api.eu-north-1.amazonaws.com/getallpackagemetadata"

    // MARK: - Get JWT

    private func getJWT() -> String? {

        guard let rawToken = AuthManager.shared.getToken() else {
            print("No token found")
            return nil
        }

        let token = rawToken.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !token.isEmpty else {
            print("Token is empty")
            return nil
        }

        // Basic JWT format check:
        // header.payload.signature
        let parts = token.components(separatedBy: ".")

        guard parts.count == 3 else {
            print("Invalid JWT format")
            return nil
        }

        return token
    }

    // MARK: - Get All Package Metadata

    func getAllPackageMetadata() async -> [Package]? {

        guard let token = getJWT() else {
            return nil
        }

        guard let url = URL(string: getAllPackageMetadataURL) else {
            print("Invalid URL")
            return nil
        }

        var request = URLRequest(url: url)

        request.httpMethod = "GET"

        // Send JWT in Authorization header
        request.setValue(
            token,
            forHTTPHeaderField: "Authorization"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        do {

            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            // Make sure we received an HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response")
                return nil
            }

            print("HTTP Status:", httpResponse.statusCode)

            // Print server response while debugging
            if let responseString = String(
                data: data,
                encoding: .utf8
            ) {
                print("Server Response:", responseString)
            }

            // Make sure request succeeded
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Request failed with status code:",
                      httpResponse.statusCode)
                return nil
            }

            do {
                // FIX 2: Try decoding as the wrapped dictionary {"packages": [...]}
                if let decoded = try? JSONDecoder().decode(
                    PackageMetadataResponse.self,
                    from: data
                ) {
                    return decoded.packages
                }
                
                // FIX 3: Fallback if the API returns a direct array [{...}, {...}] instead
                let decodedArray = try JSONDecoder().decode(
                    [Package].self,
                    from: data
                )
                return decodedArray

            } catch {

                print("JSON decoding error:", error)
                return nil
            }

        } catch {

            print("Network error:", error)
            return nil
        }
    }

    // MARK: - Find Selected Notebook

    func selectedNotebook(
        from packages: [Package],
        selection: String
    ) -> Package? {

        return packages.first {
            $0.path == selection
        }
    }
}



