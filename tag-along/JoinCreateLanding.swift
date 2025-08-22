import SwiftUI

struct JoinCreateLanding: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var groupVM: GroupViewModel
    @AppStorage("username") private var username: String = ""

    // theme
    private let bgColor      = Color(hex: "#F7F7F2")
    private let primaryGreen = Color(hex: "#07462F")
    private let tanBorder    = Color(hex: "#C4A78B")

    // state
    @State private var showConfirm = false
    @State private var isOwner: Bool? = nil
    @State private var roleLoading = false
    @State private var working = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    


    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Start or join a group")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(primaryGreen)
                        .padding(.top, 16)

                    // Create
                    NavigationLink { CreateGroup() } label: {
                        CardRow(icon: "plus.circle.fill",
                                title: "Create Group",
                                subtitle: "Make a new group and share the code.",
                                tint: primaryGreen, tanBorder: tanBorder)
                    }

                    // Join
                    NavigationLink { JoinGroupView() } label: {
                        CardRow(icon: "person.3.fill",
                                title: "Join Group",
                                subtitle: "Enter a code you got from a friend.",
                                tint: primaryGreen, tanBorder: tanBorder)
                    }

                    // Leave / End
                    if let g = groupVM.currentGroup {
                        Button {
                            showConfirm = true
                        } label: {
                        CardRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: {
                                    switch isOwner {
                                    case .none: return "Managing Current Group…"
                                    case .some(true): return "End Current Group"
                                    case .some(false): return "Leave Current Group"
                                    }
                                }(),
                                subtitle: {
                                    switch isOwner {
                                    case .some(true):  return "End “\(g.name)” for everyone."
                                    case .some(false): return "Leave “\(g.name)” and stop sharing."
                                    case .none:   return "Checking your role for “\(g.name)”…"
                                    }
                                }(),
                                tint: primaryGreen,
                                tanBorder: tanBorder
                            )
                        }
                        .disabled(roleLoading || working)
                        .overlay(alignment: .trailing) {
                                                    if roleLoading {
                                                        ProgressView().padding(.trailing, 20)
                                                    }
                                                }
                    }
                    Text("You can always view your active group from the Home tab.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(primaryGreen.opacity(0.7))
                        .padding(.top, 8)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 14)
            }
        }
        .confirmationDialog(isOwner == true ? "End Group?" : "Leave Group?",
                            isPresented: $showConfirm, titleVisibility: .visible) {
            Button(isOwner == true ? "End Group" : "Leave Group", role: .destructive) {
                guard let code = groupVM.currentGroup?.code else {
                    alertMessage = "No active group."
                    showAlert = true
                    return
                }
                leaveGroup(code: code) // <-- label + non-optional String
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(isOwner == true
                 ? "You are the owner. Ending will close the group for everyone."
                 : "You’ll be removed from the group and won’t see locations anymore.")
        }
        .alert("Group", isPresented: $showAlert) { Button("OK") {} } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Role check then confirm
    private func fetchRoleAndAsk() {
        guard let code = groupVM.currentGroup?.code else { return }
        guard let url = URL(string: "\(baseURL)/users/\(username)/active-group") else { return }

        struct ActiveGroupMini: Decodable {
            let success: Bool
            let group_code: String?
            let creator_username: String?
        }

        working = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                working = false
                if let e = error { alertMessage = e.localizedDescription; showAlert = true; return }
                guard let data = data,
                      let ag = try? JSONDecoder().decode(ActiveGroupMini.self, from: data),
                      ag.success, ag.group_code == code
                else { alertMessage = "Couldn’t verify your role."; showAlert = true; return }

                isOwner = (ag.creator_username == username)
                showConfirm = true
            }
        }.resume()
    }

    // MARK: - Leave OR End
    private struct LeaveGroupResponse: Codable {
        let success: Bool
        let message: String?
    }

    private func leaveGroup(code: String) {
        // Owner → end-by-username, Member → leave
        let endpoint = isOwner == true ? "end" : "leave"
        guard let url = URL(string: "\(baseURL)/groups/\(code)/\(endpoint)") else {
            print("⚠️ Invalid \(endpoint) URL")
            alertMessage = "Invalid server URL."
            showAlert = true
            return
        }

        // Configure the request
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        // Create & encode the body using your existing payload shape
        let email = UserDefaults.standard.string(forKey: "email")
        let body = ["user_email": email]
        struct Payload: Codable { let group_code: String; let user_username: String;}
        guard !username.isEmpty else {
            alertMessage = "No username found."; showAlert = true; return
        }
        let payload = Payload(group_code: code, user_username: username)

        do {
            if isOwner == true {
                   // owner → end request, only need email
                   req.httpBody = try JSONEncoder().encode(body)
               } else {
                   // member → leave request, needs group_code + username
                   let payload = Payload(group_code: code, user_username: username)
                   req.httpBody = try JSONEncoder().encode(payload)
               }
        } catch {
            DispatchQueue.main.async {
                alertMessage = "Failed to encode \(isOwner == true ? "end" : "leave") request"
                showAlert = true
            }
            return
        }

        // Fire off the network call
        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async {
                if let err = error {
                    alertMessage = "Network error: \(err.localizedDescription)"
                    showAlert = true
                    return
                }

                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                guard let data = data else {
                    alertMessage = "No data received"
                    showAlert = true
                    return
                }

                // Try to decode structured response; fall back to raw text
                let decoded = try? JSONDecoder().decode(LeaveGroupResponse.self, from: data)
                let bodyText = String(data: data, encoding: .utf8)

                if (200...299).contains(status), decoded?.success == true {
                    // ✅ On success, refresh shared state so all tabs/views update
                    showConfirm = false
                    isOwner = false
                    groupVM.checkForActiveGroup()
                } else {
                    alertMessage = decoded?.message ?? bodyText ?? "Server error \(status)"
                    showAlert = true
                }
            }
        }
        .resume()
    }

}

// Reusable card
private struct CardRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let tanBorder: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .frame(width: 42, height: 42)
                .foregroundColor(tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(tint)
                Text(subtitle)
                    .foregroundColor(tint.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(tint.opacity(0.8))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .stroke(tanBorder, lineWidth: 4)
                .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.6)))
        )
    }
}
