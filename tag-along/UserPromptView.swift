import SwiftUI

struct UserPromptView: View {
    @EnvironmentObject var router: Router
    let email: String
    @AppStorage("username") private var username: String = ""
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

            Text("Choose a username for\n\(email)")
                .multilineTextAlignment(.center)
                .font(.headline)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Submit", action: submitUsername)
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
    
    func submitUsername() {
        guard let url = URL(string: "http://192.168.86.65:8000/auth/username") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "email":    email,
            "username": username
        ])
        
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                let msg  = json["message"] as? String
            else {
                DispatchQueue.main.async {
                    result = "Unknown response"
                }
                return
            }
            
            DispatchQueue.main.async {
                if msg.lowercased().contains("complete") {
                    // Store username in UserDefaults for other parts of the app
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set(username, forKey: "username")
                    router.route = .home
                } else {
                    result = msg
                }
            }
        }
        .resume()
    }
}
