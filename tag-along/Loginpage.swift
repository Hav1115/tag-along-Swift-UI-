import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FirebaseCore
import UIKit

struct Loginpage: View {
  // MARK: — your state
    @EnvironmentObject var router: Router
  @State private var fullName:     String = ""
    @AppStorage("username") private var savedUsername: String = ""
  @State private var password:     String = ""
  @State private var showPassword: Bool   = false
  @State private var acceptedPP:   Bool   = false
@State private var savedEmail: String = ""
    @State private var email: String = ""
    @State private var result: String = ""

  // MARK: — customize these!
  private let bgColor        = Color(hex: "#F7F7F2") // screen background
  private let buttonGray     = Color(hex: "#8E8E92") // Apple & Get Started bg
  private let outlineGray    = Color(hex: "#E5E5EA") // Google button border & fields
  private let tanBorder      = Color(hex: "#C4A78B") // input field border
  private let primaryGreen   = Color(hex: "#07462F") // headings, checkmark, links

  var body: some View {
    ZStack {
      // 1️⃣ full-screen background
      bgColor
        .ignoresSafeArea()

      VStack(spacing: 24) {
        Spacer().frame(height: 20)

        // 2️⃣ Title
        Text("Welcome Back!")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(primaryGreen)
          .padding(.top, 35)

        // 3️⃣ Continue with Apple
          // Apple Button
          Button(action: { router.route = .tabs(start: 0) }) {
            HStack(spacing: 12) {
              Image(systemName: "applelogo")
                .font(.system(size: 20, weight: .medium))

              Text("CONTINUE WITH APPLE")
                .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(buttonGray)
            .cornerRadius(25)
          }
          .padding(.horizontal, 20)
          .padding(.top, 30)

          // Google Button
          Button(action: { router.route = .googleSignup }) {
            HStack(spacing: 12) {
              Image("googlelogo")
                .resizable()
                .frame(width: 20, height: 20)

              Text("CONTINUE WITH GOOGLE")
                .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 24)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .overlay(
              RoundedRectangle(cornerRadius: 25)
                .stroke(outlineGray, lineWidth: 1)
            )
            .background(
              Color.white
                .clipShape(RoundedRectangle(cornerRadius: 25))
            )
          }
          .padding(.horizontal, 20)

        // 5️⃣ Link to email flow
          HStack(spacing: 4) {
            Text("Login with email")
              .foregroundColor(primaryGreen)
              .font(.system(size: 14, weight: .semibold))
            
            Text("or don't have an account?")
              .foregroundColor(.secondary)
              .font(.system(size: 14))

            Button(action: {
              router.route = .signupHome // navigate to login screen
            }) {
              Text("Sign Up Now")
                .underline()
                .foregroundColor(primaryGreen)
                .font(.system(size: 14, weight: .semibold))
            }
          }
          .padding(.top, 20)

        // 6️⃣ Name field
        ZStack(alignment: .trailing) {
          TextField("Enter Email", text: $email)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
              RoundedRectangle(cornerRadius: 15)
                .stroke(tanBorder, lineWidth: 1.5)
            )

          if !email.isEmpty {
            Image(systemName: "checkmark")
              .foregroundColor(primaryGreen)
              .padding(.trailing, 16)
          }
        }
        .padding(.horizontal, 20)

        // 7️⃣ Password field
        ZStack(alignment: .trailing) {
          Group {
            if showPassword {
              TextField("Password", text: $password)
            } else {
              SecureField("Password", text: $password)
            }
          }
          .padding(.horizontal, 16)
          .frame(height: 50)
          .background(
            RoundedRectangle(cornerRadius: 15)
              .stroke(tanBorder, lineWidth: 1.5)
          )

          Button(action: { showPassword.toggle() }) {
            Image(systemName: showPassword ? "eye.slash" : "eye")
              .foregroundColor(.secondary)
              .padding(.trailing, 16)
          }
        }
        .padding(.horizontal, 20)


        // 9️⃣ Get Started button
        Button(action: { login() }) {
          Text("Login")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(buttonGray)
            .cornerRadius(25)
            if !result.isEmpty {
              Text(result)
                .foregroundColor(.red)
                .font(.caption)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .disabled(email.isEmpty || password.isEmpty)
        .opacity((!email.isEmpty && !password.isEmpty) ? 1 : 0.6)

        Spacer().frame(height: 16)
      }
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
                        router.route = .duckwalk
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
