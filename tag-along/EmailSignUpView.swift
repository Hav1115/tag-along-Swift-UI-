//
//  EmailSignUpView.swift
//  tag-along
//
//  Created by Havish Komatreddy on 6/26/25.
//

// EmailSignUpView.swift
import SwiftUI

struct EmailSignUpView: View {
    @EnvironmentObject var router: Router
    @State private var email: String = ""
    @State private var password = ""
    @State private var result   = ""
    
    var body: some View {
        VStack(spacing: 16) {
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

            Text("Email Sign Up")
                .font(.title)
                .padding()
            
            HStack {
                TextField("Email",    text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Clear") {
                    email = ""
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign Up", action: signup)
                .buttonStyle(.borderedProminent)
            
            Text(result)
                .foregroundColor(.red)
                .font(.caption)
            Spacer()
        }
        .padding()
        .navigationTitle("") 
        .navigationBarBackButtonHidden(true)
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
        }
        .resume()
    }
}
