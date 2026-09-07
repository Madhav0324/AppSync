//
//  RootView.swift
//  AppSync
//
//  Created by Madhav Choudhary on 03/09/26.
//

import SwiftUI

struct RootView: View {

    
    @State private var isLoggedIn = false

    var body: some View {

        Group {

            if isLoggedIn {

                // 🟢 CHANGED:
                // Pass the AuthManager object to HomeView.
                HomeView(
                    onSignOut: {

                        // 🟢 CHANGED:
                        // Update RootView's UI state.
                        isLoggedIn = false
                    }
                )

            } else {

                // 🟢 CHANGED:
                // Pass the SAME AuthManager object to LoginView.
                LoginView(
                    onLoginSuccess: {

                        // 🟢 CHANGED:
                        // Login succeeded, so show HomeView.
                        isLoggedIn = true
                    }
                )
            }
        }

        // 🟢 CHANGED:
        // When RootView first appears, ask AuthManager
        // whether the user is already signed in.
        .onAppear {

            isLoggedIn = AuthManager.shared.isSignedIn()
        }

        .animation(
            .easeInOut,
            value: isLoggedIn
        )
    }
}


// MARK: - Preview

#Preview {
    RootView()
}
