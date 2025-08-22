//
//  AccountScreen.swift
//  tag-along
//
//  Created by Havish Komatreddy on 8/7/25.
//

import SwiftUI

struct AccountScreen: View {
    @EnvironmentObject var router: Router
    @AppStorage("username") private var username: String = ""
    @AppStorage("email")    private var email: String = ""

    private let bgColor      = Color(hex: "#F7F7F2")
    private let primaryGreen = Color(hex: "#07462F")
    private let border       = Color(hex: "#C4A78B")

    @State private var showLogoutConfirm = false

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            Form {
                // Profile
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(primaryGreen)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(username.isEmpty ? "Guest" : username)
                                .font(.headline)
                                .foregroundColor(primaryGreen)
                            Text(email.isEmpty ? "No email" : email)
                                .font(.subheadline)
                                .foregroundColor(primaryGreen.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Profile")
                }

                // Settings (stubs you can wire up)
                Section("Preferences") {
                    NavigationLink("Notifications") { Text("Notification Settings") }
                    NavigationLink("Privacy")       { Text("Privacy Settings") }
                }

                // Danger / session
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "power")
                            Text("Log Out")
                        }
                    }
                }
            }
        }
        .tint(primaryGreen)
        .confirmationDialog("Log out of your account?",
                            isPresented: $showLogoutConfirm,
                            titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { logout() }
            Button("Cancel", role: .cancel) { }
        }
        .navigationTitle("Account")
    }

    private func logout() {
        // clear what you store
        UserDefaults.standard.set("", forKey: "email")
        UserDefaults.standard.set("", forKey: "username")
        // back to auth
        router.route = .login
    }
}
