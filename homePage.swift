import SwiftUI

struct HomeView: View {

    // MARK: - GetData

    private let getData = GetData()

    // MARK: - Package Data

    @State private var packages: [Package] = []

    // MARK: - UI State

    @State private var showPackages = false
    @State private var isLoading = false

    // MARK: - Sign Out

    var onSignOut: () -> Void

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

                VStack(spacing: 25) {

                    // MARK: - Title

                    Text("Welcome")
                        .font(
                            .system(
                                size: 36,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)

                    Text("You are successfully signed in.")
                        .foregroundStyle(
                            .white.opacity(0.6)
                        )

                    // MARK: - Download Package Button

                    Button {

                        // Start loading
                        isLoading = true

                        Task {

                            // Get packages from API
                            if let receivedPackages =
                                await getData.getAllPackageMetadata() {

                                // Store packages
                                packages = receivedPackages

                                // Show package list
                                showPackages = true

                                print(
                                    "✅ Received \(receivedPackages.count) packages"
                                )
                            } else {

                                print(
                                    "❌ Failed to receive packages"
                                )
                            }

                            // Stop loading
                            isLoading = false
                        }

                    } label: {

                        HStack {

                            if isLoading {

                                ProgressView()
                                    .tint(.white)

                            } else {

                                Image(
                                    systemName: "arrow.down.circle"
                                )
                            }

                            Text(
                                isLoading
                                ? "Loading Packages..."
                                : "Download Package"
                            )
                        }
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    .blue,
                                    .purple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 18
                            )
                        )
                    }
                    .disabled(isLoading)

                    // MARK: - Package List

                    if showPackages {

                        VStack(
                            alignment: .leading,
                            spacing: 12
                        ) {

                            Text("Your Notebooks")
                                .font(
                                    .system(
                                        size: 20,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.white)

                            // MARK: - Packages

                            ForEach(
                                packages,
                                id: \.id
                            ) { package in

                                // MARK: - Package Button

                                Button {

                                    print(
                                        "📦 Selected package:"
                                    )

                                    print(
                                        "ID: \(package.id)"
                                    )

                                    print(
                                        "Path: \(package.path)"
                                    )

                                    print(
                                        "Last Modified: \(package.lastMod)"
                                    )

                                    // Later:
                                    // Call your package download API here.

                                } label: {

                                    HStack {

                                        // Package icon
                                        Image(
                                            systemName:
                                                "shippingbox"
                                        )

                                        // Package path
                                        Text(package.path!)
                                            .lineLimit(1)

                                        Spacer()

                                        // Arrow
                                        Image(
                                            systemName:
                                                "chevron.right"
                                        )
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(
                                        .white.opacity(0.08)
                                    )
                                    .overlay(
                                        RoundedRectangle(
                                            cornerRadius: 15
                                        )
                                        .stroke(
                                            .white.opacity(0.12),
                                            lineWidth: 1
                                        )
                                    )
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 15
                                        )
                                    )
                                }
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                    }

                    // MARK: - Sign Out

                    Button {

                        // Remove authentication tokens
                        AuthManager.shared.signOut()

                        // Tell RootView to show LoginView
                        onSignOut()

                    } label: {

                        HStack {

                            Image(
                                systemName:
                                    "rectangle.portrait.and.arrow.right"
                            )

                            Text("Sign Out")
                        }
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            .white.opacity(0.08)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 18
                            )
                            .stroke(
                                .white.opacity(0.15),
                                lineWidth: 1
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 18
                            )
                        )
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 30)
            }
        }
    }
}

// MARK: - Preview

#Preview {

    HomeView(
        onSignOut: {

            print("User signed out")
        }
    )
}
