import SwiftUI
import Foundation

struct LoginView: View {

    // MARK: - User Input

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    // MARK: - Saved Credentials

    @AppStorage("savedEmail")
    private var savedEmail = ""

    @AppStorage("savedPassword")
    private var savedPassword = ""

    // MARK: - Login Success

    var onLoginSuccess: () -> Void

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

            // MARK: - Decorative Circles

            Circle()
                .fill(Color.purple.opacity(0.25))
                .frame(width: 250)
                .blur(radius: 70)
                .offset(x: 150, y: -350)

            Circle()
                .fill(Color.blue.opacity(0.20))
                .frame(width: 220)
                .blur(radius: 70)
                .offset(x: -150, y: 350)

            // MARK: - Login Content

            ScrollView {

                VStack(spacing: 0) {

                    // MARK: - App Icon

                    ZStack {

                        RoundedRectangle(cornerRadius: 25)
                            .fill(.white.opacity(0.10))
                            .frame(width: 90, height: 90)

                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.top, 60)

                    // MARK: - Title

                    Text("Welcome Back")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 28)

                    Text("Sign in to continue your journey")
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 8)

                    // MARK: - Email

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Email")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.purple)

                        HStack(spacing: 14) {

                            Image(systemName: "envelope")
                                .foregroundStyle(.white.opacity(0.6))

                            TextField(
                                "Enter your email",
                                text: $email
                            )
                            .foregroundStyle(.white)
                            .tint(.purple)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                        }
                        .padding()
                        .background(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    .white.opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .padding(.top, 45)

                    // MARK: - Password

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Password")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.purple)

                        HStack(spacing: 14) {

                            Image(systemName: "lock")
                                .foregroundStyle(.white.opacity(0.6))

                            if showPassword {

                                TextField(
                                    "Enter your password",
                                    text: $password
                                )
                                .foregroundStyle(.white)
                                .tint(.purple)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)

                            } else {

                                SecureField(
                                    "Enter your password",
                                    text: $password
                                )
                                .foregroundStyle(.white)
                                .tint(.purple)
                            }

                            Button {

                                showPassword.toggle()

                            } label: {

                                Image(
                                    systemName: showPassword
                                    ? "eye.slash"
                                    : "eye"
                                )
                                .foregroundStyle(
                                    .white.opacity(0.6)
                                )
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    .white.opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .padding(.top, 25)

                    // MARK: - Forgot Password

                    HStack {

                        Spacer()

                        Button("Forgot Password?") {

                            print("Forgot password tapped")
                        }
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.purple)
                    }
                    .padding(.top, 15)

                    // MARK: - Login Button

                    Button {

                        Task {

                            let success = await AuthManager.shared.signIn(
                                username: email,
                                password: password
                            )

                            if success {

                                // Save credentials for prototype
                                savedEmail = email
                                savedPassword = password

                                // Tell RootView login succeeded
                                onLoginSuccess()

                            } else {

                                print("Login failed")
                            }
                        }

                    } label: {

                        Text("Login")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [
                                        .blue,
                                        .purple,
                                        .pink
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
                    .padding(.top, 30)

                    // MARK: - Divider

                    HStack {

                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(
                                .white.opacity(0.15)
                            )

                        Text("OR")
                            .font(.caption)
                            .foregroundStyle(
                                .white.opacity(0.5)
                            )

                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(
                                .white.opacity(0.15)
                            )
                    }
                    .padding(.vertical, 28)

                    // MARK: - Apple Login

                    Button {

                        print("Apple login tapped")

                    } label: {

                        HStack {

                            Image(systemName: "apple.logo")

                            Text("Continue with Apple")
                        }
                        .font(
                            .system(
                                size: 16,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            .white.opacity(0.07)
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

                    // MARK: - Sign Up

                    HStack {

                        Text("Don't have an account?")
                            .foregroundStyle(
                                .white.opacity(0.55)
                            )

                        Button("Sign Up") {

                            print("Sign up tapped")
                        }
                        .foregroundStyle(.purple)
                        .fontWeight(.semibold)
                    }
                    .font(.system(size: 15))
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 25)
            }
        }
    }
}

// MARK: - Preview

#Preview {

    LoginView(
        onLoginSuccess: {

            print("Login successful")
        }
    )
}
