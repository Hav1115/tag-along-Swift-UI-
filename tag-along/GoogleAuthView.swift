//
//  GoogleAuthView.swift
//  tag-along
//
//  Created by Havish Komatreddy on 6/26/25.
//

// ... rest of GoogleAuthView and AppleAuthView remain the same for now
import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FirebaseCore
import UIKit

struct GoogleAuthView: View {
    @EnvironmentObject var router: Router
    @State private var result = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { router.route = .signupHome }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.top)

            Button("Sign in with Google") {
                startGoogleSignIn()    // ← calls your helper
            }
            .frame(maxWidth: .infinity, minHeight: 45)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)

            Text(result)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .navigationTitle("Google Sign-In")
        .navigationBarBackButtonHidden(true)
    }

    /// Put your helper right here in the same struct:
    private func startGoogleSignIn() {
        // 1) Configure the SDK
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            result = "❌ Missing clientID"
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        // 2) Find a view controller to present from
        guard
            let scene = UIApplication.shared.connectedScenes
                           .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else {
            result = "❌ No root VC"
            return
        }

        // 3) Launch the Google sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: root) { signInResult, error in
            if let error = error {
                result = "❌ \(error.localizedDescription)"
                return
            }
            guard let idToken = signInResult?.user.idToken?.tokenString else {
                result = "❌ No ID token"
                return
            }
            callBackend(idToken: idToken)
        }
    }

    /// And your network call…
    private func callBackend(idToken: String) {
        // …POST to /auth/google, update `result` on completion
    }
}
