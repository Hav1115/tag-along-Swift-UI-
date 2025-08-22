import SwiftUI

struct EmailLogin: View {
    @EnvironmentObject var router: Router

    @State private var savedEmail: String = ""
    @AppStorage("username") private var savedUsername: String = ""
    @AppStorage("email") private var email: String = ""
    @State private var password: String = ""
    @State private var result: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // Custom back button
            HStack {
                Button(action: {
                    router.route = .login
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.top)

            Text("Email Login")
                .font(.title)
                .padding(.bottom)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Log In", action: login)
                .buttonStyle(.borderedProminent)

            Text(result)
                .foregroundColor(.red)
                .font(.caption)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            email = savedEmail
        }
    }

    func login() {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            result = "Invalid login URL"
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    result = "Network error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    result = "No data in response"
                }
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let msg = (json["message"] as? String) ?? "Incorrect email or password"
                let needUsername = (json["need_username"] as? Bool) ?? false
                let username = json["username"] as? String

                DispatchQueue.main.async {
                    if msg.lowercased().contains("login successful") {
                        savedEmail = email
                        if let username = username {
                            savedUsername = username
                            // Store in UserDefaults for other parts of the app
                            UserDefaults.standard.set(email, forKey: "email")
                            UserDefaults.standard.set(username, forKey: "username")
                        }
                        router.route = .home
                    } else if needUsername || msg.lowercased().contains("username required") {
                        router.route = .userPrompt(email: email)
                    } else {
                        result = msg
                    }
                }
            } else {
                let raw = String(data: data, encoding: .utf8) ?? "Invalid response"
                DispatchQueue.main.async {
                    result = raw
                }
            }
        }.resume()
    }
}
