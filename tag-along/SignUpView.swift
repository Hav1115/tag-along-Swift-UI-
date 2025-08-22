import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FirebaseCore
import UIKit

struct SignUpView: View {
  // MARK: — your state
    @EnvironmentObject var router: Router
  @State private var fullName:     String = ""
  @State private var password:     String = ""
  @State private var showPassword: Bool   = false
  @State private var acceptedPP:   Bool   = false
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
        Text("Create Account!")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(primaryGreen)
          .padding(.top, 35)

        // 3️⃣ Continue with Apple
          // Apple Button
          Button(action: { router.route = .appleSignup }) {
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
            Text("Create account with email")
              .foregroundColor(primaryGreen)
              .font(.system(size: 14, weight: .semibold))
            
            Text("or")
              .foregroundColor(.secondary)
              .font(.system(size: 14))

            Button(action: {
              router.route = .login // navigate to login screen
            }) {
              Text("Login")
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

        // 8️⃣ Privacy Policy checkbox
        HStack {
          (
            Text("I have read the ")
              .foregroundColor(.secondary)
            +
            Text("Privacy Policy")
              .foregroundColor(primaryGreen)
              .fontWeight(.semibold)
          )
          Spacer()
          Button(action: { acceptedPP.toggle() }) {
            Image(systemName: acceptedPP
                  ? "checkmark.square.fill"
                  : "square")
              .font(.system(size: 24))
              .foregroundColor(acceptedPP ? primaryGreen : .secondary)
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)

        Spacer()

        // 9️⃣ Get Started button
        Button(action: { signup() }) {
          Text("GET STARTED")
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
        .disabled(!acceptedPP || email.isEmpty || password.isEmpty)
        .opacity((acceptedPP && !email.isEmpty && !password.isEmpty) ? 1 : 0.6)

        Spacer().frame(height: 16)
      }
    }
      
  }
    func signup() {
        print("🔵 Attempting signup with email: \(email)")
        guard let url = URL(string: "\(baseURL)/auth/email-signup") else {
            print("🔵 Invalid URL")
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "email":    email,
            "password": password
        ])
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("🔵 Network error: \(error)")
                DispatchQueue.main.async {
                    result = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔵 HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("🔵 No data received")
                DispatchQueue.main.async {
                    result = "No data received"
                }
                return
            }
            
            let str = String(data: data, encoding: .utf8) ?? "Unknown response"
            print("🔵 Response: \(str)")
            
            DispatchQueue.main.async {
                result = str
                if str.contains("username") || str.contains("Email accepted") {
                    UserDefaults.standard.set(email, forKey: "email")
                    router.route = .userPrompt(email: email)
                }
            }
        }.resume()
    }

}
