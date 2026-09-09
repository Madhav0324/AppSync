import Foundation

class AuthManager {

    static let shared = AuthManager()

    private init() {}

    // MARK: - UserDefaults Keys

    private let tokenKey = "authToken"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let usernameKey = "username"

    // MARK: - Cognito Configuration

    private let cognitoURL = URL(
        string: "https://cognito-idp.eu-north-1.amazonaws.com/"
    )!

    private let clientId = "388s6r4q4n7e40gv66m0qea6v8"

    // MARK: - Sign In

    func signIn(
        username: String,
        password: String
    ) async -> Bool {

        let requestBody: [String: Any] = [

            "AuthFlow": "USER_PASSWORD_AUTH",

            "ClientId": clientId,

            "AuthParameters": [
                "USERNAME": username,
                "PASSWORD": password
            ]
        ]

        do {

            // MARK: - Convert Request To JSON

            let jsonData =
                try JSONSerialization.data(
                    withJSONObject: requestBody
                )

            // MARK: - Create Request

            var request =
                URLRequest(
                    url: cognitoURL
                )

            request.httpMethod = "POST"

            request.setValue(
                "application/x-amz-json-1.1",
                forHTTPHeaderField: "Content-Type"
            )

            request.setValue(
                "AWSCognitoIdentityProviderService.InitiateAuth",
                forHTTPHeaderField: "X-Amz-Target"
            )

            request.httpBody = jsonData

            // MARK: - Send Request

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            // MARK: - HTTP Response

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print("❌ Invalid response from Cognito")
                return false
            }

            // MARK: - Check Response Status

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ Cognito authentication failed. Status code:",
                    httpResponse.statusCode
                )

                if let errorResponse =
                    String(
                        data: data,
                        encoding: .utf8
                    ) {

                    print("Cognito response:")
                    print(errorResponse)
                }

                return false
            }

            // MARK: - Convert Response To Dictionary

            guard let json =
                    try JSONSerialization.jsonObject(
                        with: data
                    ) as? [String: Any] else {

                print("❌ Could not decode Cognito response")
                return false
            }

            // MARK: - Authentication Result

            guard let authResult =
                    json["AuthenticationResult"]
                    as? [String: Any] else {

                print("❌ AuthenticationResult not found")
                print(json)

                return false
            }

            // MARK: - Get ID Token

            guard let idToken =
                    authResult["IdToken"] as? String else {

                print("❌ ID token not found")
                print(authResult)

                return false
            }

            // MARK: - Get Access Token

            guard let accessToken =
                    authResult["AccessToken"] as? String else {

                print("❌ Access token not found")
                print(authResult)

                return false
            }

            // MARK: - Get Refresh Token

            guard let refreshToken =
                    authResult["RefreshToken"] as? String else {

                print("❌ Refresh token not found")
                print(authResult)

                return false
            }

            // MARK: - Save Tokens

            UserDefaults.standard.set(
                idToken,
                forKey: tokenKey
            )

            UserDefaults.standard.set(
                accessToken,
                forKey: accessTokenKey
            )

            UserDefaults.standard.set(
                refreshToken,
                forKey: refreshTokenKey
            )

            // MARK: - Save Username

            UserDefaults.standard.set(
                username,
                forKey: usernameKey
            )

            // MARK: - Confirm Login

            print("✅ Sign in successful")
            print("✅ ID token saved")
            print("✅ Access token saved")
            print("✅ Refresh token saved")
            print("✅ Username saved:", username)

            return true

        } catch {

            print(
                "❌ Sign in failed:",
                error.localizedDescription
            )

            return false
        }
    }

    // MARK: - CHANGED:
    // Refresh Cognito Tokens

    func refreshToken() async -> Bool {

        // Get the refresh token that was saved
        // during sign in.

        guard let refreshToken =
                UserDefaults.standard.string(
                    forKey: refreshTokenKey
                ) else {

            print("❌ Refresh token not found")

            return false
        }

        // MARK: - Create Refresh Request Body

        let requestBody: [String: Any] = [

            "AuthFlow": "REFRESH_TOKEN_AUTH",

            "ClientId": clientId,

            "AuthParameters": [
                "REFRESH_TOKEN": refreshToken
            ]
        ]

        do {

            // MARK: - Convert Request To JSON

            let jsonData =
                try JSONSerialization.data(
                    withJSONObject: requestBody
                )

            // MARK: - Create Request

            var request =
                URLRequest(
                    url: cognitoURL
                )

            request.httpMethod = "POST"

            request.setValue(
                "application/x-amz-json-1.1",
                forHTTPHeaderField: "Content-Type"
            )

            request.setValue(
                "AWSCognitoIdentityProviderService.InitiateAuth",
                forHTTPHeaderField: "X-Amz-Target"
            )

            request.httpBody = jsonData

            // MARK: - Send Request

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            // MARK: - HTTP Response

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                print("❌ Invalid Cognito response")

                return false
            }

            // MARK: - Check Response Status

            guard httpResponse.statusCode == 200 else {

                print(
                    "❌ Token refresh failed. Status code:",
                    httpResponse.statusCode
                )

                if let error =
                    String(
                        data: data,
                        encoding: .utf8
                    ) {

                    print("Cognito response:")
                    print(error)
                }

                return false
            }

            // MARK: - Convert Response To Dictionary

            guard let json =
                    try JSONSerialization.jsonObject(
                        with: data
                    ) as? [String: Any] else {

                print(
                    "❌ Could not decode refresh response"
                )

                return false
            }

            // MARK: - Authentication Result

            guard let authResult =
                    json["AuthenticationResult"]
                    as? [String: Any] else {

                print(
                    "❌ AuthenticationResult not found"
                )

                print(json)

                return false
            }

            // MARK: - Get New ID Token

            guard let newIdToken =
                    authResult["IdToken"] as? String else {

                print(
                    "❌ New ID token not found"
                )

                print(authResult)

                return false
            }

            // MARK: - Get New Access Token

            guard let newAccessToken =
                    authResult["AccessToken"] as? String else {

                print(
                    "❌ New access token not found"
                )

                print(authResult)

                return false
            }

            // MARK: - Save New ID Token

            UserDefaults.standard.set(
                newIdToken,
                forKey: tokenKey
            )

            // MARK: - Save New Access Token

            UserDefaults.standard.set(
                newAccessToken,
                forKey: accessTokenKey
            )

            // MARK: - Confirm Refresh

            print("✅ Tokens refreshed successfully")
            print("✅ New ID token saved")
            print("✅ New access token saved")

            return true

        } catch {

            print(
                "❌ Token refresh error:",
                error.localizedDescription
            )

            return false
        }
    }

    // MARK: - Get Authentication Token

    func getToken() -> String? {

        return UserDefaults.standard.string(
            forKey: tokenKey
        )
    }

    // MARK: - Get Access Token

    func getAccessToken() -> String? {

        return UserDefaults.standard.string(
            forKey: accessTokenKey
        )
    }

    // MARK: - Get Username

    func getUsername() -> String? {

        return UserDefaults.standard.string(
            forKey: usernameKey
        )
    }

    // MARK: - Sign Out

    func signOut() {

        UserDefaults.standard.removeObject(
            forKey: tokenKey
        )

        UserDefaults.standard.removeObject(
            forKey: accessTokenKey
        )

        UserDefaults.standard.removeObject(
            forKey: refreshTokenKey
        )

        UserDefaults.standard.removeObject(
            forKey: usernameKey
        )

        print("✅ Signed out")
    }

    // MARK: - Is Signed In

    func isSignedIn() -> Bool {

        let token =
            UserDefaults.standard.string(
                forKey: tokenKey
            )

        return token != nil
    }
}
