//
//  AppleAuthView.swift
//  tag-along
//
//  Created by Havish Komatreddy on 6/26/25.
//
import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FirebaseCore
import UIKit

struct AppleAuthView: View {
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

            SignInWithAppleButton(
              .signIn,
              onRequest: { request in
                  request.requestedScopes = [.email, .fullName]
              },
              onCompletion: handleApple
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 45)
            
            Text(result)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }

    private func handleApple(_ authResult: Result<ASAuthorization, Error>) {
        switch authResult {
        case .failure(let err):
            result = "❌ \(err.localizedDescription)"
        case .success(let auth):
            guard
              let cred = auth.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
            else {
                result = "❌ Unable to fetch identity token"
                return
            }
            // Optional: grab fullName/email here for UX
            callBackend(idToken: idToken)
        }
    }

    private func callBackend(idToken: String) {
        guard let url = URL(string: "http://localhost:8000/auth/apple") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["identity_token": idToken]
        req.httpBody = try? JSONEncoder().encode(body)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if
              let data = data,
              let str = String(data: data, encoding: .utf8)
            {
                DispatchQueue.main.async { result = str }
            }
        }.resume()
    }
}

