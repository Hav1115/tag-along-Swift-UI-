import Foundation

// MARK: - Data Models
struct JoinGroupRequest: Codable {
    let group_code: String
    let user_username: String
}

struct JoinGroupResponse: Codable {
    let success: Bool
    let message: String?
    let group_code: String?
    let group_name: String?
    let members: [String]?
    let created_at: String?
    let expires_at: String?
}

// MARK: - Join Group Function
func joinGroup(groupCode: String, username: String, completion: @escaping (Result<JoinGroupResponse, Error>) -> Void) {
    // Validate input
    guard !groupCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        completion(.failure(JoinGroupError.invalidGroupCode))
        return
    }
    
    guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        completion(.failure(JoinGroupError.invalidUsername))
        return
    }
    
    // Configure the API endpoint - replace with your actual backend URL
    guard let url = URL(string: "\(baseURL)/groups/join") else {
        completion(.failure(JoinGroupError.invalidURL))
        return
    }
    
    // Create the request body
    let requestBody = JoinGroupRequest(
        group_code: groupCode.trimmingCharacters(in: .whitespacesAndNewlines),
        user_username: username.trimmingCharacters(in: .whitespacesAndNewlines)
    )
    
    // Configure the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        request.httpBody = try JSONEncoder().encode(requestBody)
    } catch {
        completion(.failure(JoinGroupError.encodingError))
        return
    }
    
    // Make the network request
    URLSession.shared.dataTask(with: request) { data, response, error in
        // Handle network errors
        if let error = error {
            DispatchQueue.main.async {
                completion(.failure(JoinGroupError.networkError(error.localizedDescription)))
            }
            return
        }
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                completion(.failure(JoinGroupError.invalidResponse))
            }
            return
        }
        
        // Handle HTTP status codes
        guard httpResponse.statusCode == 200 else {
            DispatchQueue.main.async {
                completion(.failure(JoinGroupError.httpError(httpResponse.statusCode)))
            }
            return
        }
        
        // Parse response data
        guard let data = data else {
            DispatchQueue.main.async {
                completion(.failure(JoinGroupError.noData))
            }
            return
        }
        
        do {
            let response = try JSONDecoder().decode(JoinGroupResponse.self, from: data)
            DispatchQueue.main.async {
                completion(.success(response))
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(JoinGroupError.decodingError))
            }
        }
    }.resume()
}

// MARK: - Error Types
enum JoinGroupError: Error, LocalizedError {
    case invalidGroupCode
    case invalidUsername
    case invalidURL
    case encodingError
    case networkError(String)
    case invalidResponse
    case httpError(Int)
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidGroupCode:
            return "Please enter a valid group code"
        case .invalidUsername:
            return "Username is required"
        case .invalidURL:
            return "Invalid server URL"
        case .encodingError:
            return "Failed to encode request data"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode):
            return "Server error: \(statusCode)"
        case .noData:
            return "No data received from server"
        case .decodingError:
            return "Failed to decode server response"
        }
    }
}

// MARK: - Usage Example
class GroupManager {
    func joinGroupExample(groupCode: String, username: String) {
        joinGroup(groupCode: groupCode, username: username) { result in
            switch result {
            case .success(let response):
                if response.success {
                    print("✅ Successfully joined group!")
                    print("Group Code: \(response.group_code ?? "N/A")")
                    print("Group Name: \(response.group_name ?? "Unnamed Group")")
                    print("Members: \(response.members?.joined(separator: ", ") ?? "None")")
                    print("Created: \(response.created_at ?? "N/A")")
                    print("Expires: \(response.expires_at ?? "Never")")
                } else {
                    print("❌ Failed to join group: \(response.message ?? "Unknown error")")
                }
                
            case .failure(let error):
                print("❌ Error joining group: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - SwiftUI Integration Example
#if canImport(SwiftUI)
import SwiftUI

import SwiftUI

struct JoinGroupView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var groupVM: GroupViewModel          // ← shared VM
    @AppStorage("username") private var username: String = ""

    // UI state
    @State private var groupCode = ""
    @State private var isLoadingJoin = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    // theme
    private let bgColor      = Color(hex: "#F7F7F2")
    private let primaryGreen = Color(hex: "#07462F")
    private let tanBorder    = Color(hex: "#C4A78B")
    private let buttonGray   = Color(hex: "#8E8E92")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if let g = groupVM.currentGroup {
                // ✅ Already in a group
                VStack(spacing: 12) {
                    Spacer(minLength: 40)
                    Text("Hey!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(primaryGreen)
                    Text("You're already in a group")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(primaryGreen)
                    if !g.name.isEmpty {
                        Text("(\(g.name))").foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .task { groupVM.checkForActiveGroup() } // keep in sync

            } else {
                // ❌ Not in a group → Join UI
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    Text("Join Group")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(primaryGreen)

                    TextField("Enter Code Here", text: $groupCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                        .keyboardType(.asciiCapable)
                        .onChange(of: groupCode) { groupCode = $0.uppercased() }
                        .padding(.vertical, 18)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(tanBorder, lineWidth: 4)
                        )
                        .padding(.horizontal, 28)

                    Spacer()

                    Button(action: joinTapped) {
                        if isLoadingJoin { ProgressView() }
                        else { Text("Join").font(.system(size: 22, weight: .semibold)) }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(isJoinDisabled ? buttonGray : primaryGreen)
                    .clipShape(Capsule())
                    .padding(.horizontal, 16)
                    .disabled(isJoinDisabled)

                    Spacer(minLength: 20)
                }
            }
        }
        .alert("Join Group", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(alertMessage) }
        .task {
            // make sure state is fresh when landing here
            groupVM.checkForActiveGroup()
        }
    }

    private var isJoinDisabled: Bool {
        groupCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoadingJoin
    }

    private func joinTapped() {
        let code = groupCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        isLoadingJoin = true

        joinGroup(groupCode: code, username: username) { result in
            isLoadingJoin = false
            switch result {
            case .success(let resp) where resp.success:
                groupVM.checkForActiveGroup()      // refresh shared state
                // Optional: jump to Home tab after joining:
                // router.route = .tabs(start: 0)

            case .success(let resp):
                alertMessage = resp.message ?? "Couldn’t join. Try again."
                showAlert = true

            case .failure(let err):
                alertMessage = err.localizedDescription
                showAlert = true
            }
        }
    }
}


    // 1) Add this response type alongside your other models:
    private struct LeaveGroupResponse: Codable {
        let success: Bool
        let message: String?
    }

//    private func leaveGroup(code: String) {
//        // Choose the appropriate endpoint based on whether user is owner
//        let endpoint = isOwner ? "end-by-username" : "leave"
//        guard let url = URL(string: "http://192.168.86.246:8000/groups/\(code)/\(endpoint)") else {
//            print("⚠️ Invalid \(endpoint)‑group URL")
//            return
//        }
//
//        // Configure the request
//        var req = URLRequest(url: url)
//        req.httpMethod = "POST"
//        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        // Create & encode the body using your existing JoinGroupRequest
//        let payload = JoinGroupRequest(group_code: code, user_username: username)
//        do {
//            req.httpBody = try JSONEncoder().encode(payload)
//        } catch {
//            DispatchQueue.main.async {
//                alertMessage = "Failed to encode \(isOwner ? "end" : "leave") request"
//                showAlert = true
//            }
//            return
//        }
//
//        // Fire off the network call
//        URLSession.shared.dataTask(with: req) { data, _, error in
//            DispatchQueue.main.async {
//                if let err = error {
//                    alertMessage = "Network error: \(err.localizedDescription)"
//                    showAlert = true
//                    return
//                }
//                guard let data = data else {
//                    alertMessage = "No data received"
//                    showAlert = true
//                    return
//                }
//                do {
//                    let resp = try JSONDecoder().decode(LeaveGroupResponse.self, from: data)
//                    if resp.success {
//                        // On success, clear activeGroup
//                        activeGroup = nil
//                    } else {
//                        alertMessage = resp.message ?? "Could not \(isOwner ? "end" : "leave") group"
//                        showAlert = true
//                    }
//                } catch {
//                    alertMessage = "Decoding error: \(error.localizedDescription)"
//                    showAlert = true
//                }
//            }
//        }
//        .resume()
//    }
//
//  private func checkUserRoleAndShowConfirmation(group: ActiveGroup) {
//    // Check if current user is the creator/owner
//    print("🔍 DEBUG: Checking user role")
//    print("🔍 Current username: \(username)")
//    print("🔍 Group creator: \(group.creator_username ?? "nil")")
//    print("🔍 Group members: \(group.members?.joined(separator: ", ") ?? "nil")")
//    
//    isOwner = (group.creator_username == username)
//    print("🔍 Is owner: \(isOwner)")
//    showLeaveConfirmation = true
//  }
//}

struct ActiveGroup: Decodable {
  let success: Bool
  let message: String?
  let group_code: String?
  let group_name: String?
  let members: [String]?
  let created_at: String?
  let expires_at: String?
  let creator_username: String?
}

func fetchActiveGroup(username: String,
                      completion: @escaping (Result<ActiveGroup, Error>) -> Void)
{
  guard let url = URL(string: "\(baseURL)/users/\(username)/active-group")
  else { return completion(.failure(JoinGroupError.invalidURL)) }

  URLSession.shared.dataTask(with: url) { data, resp, err in
    DispatchQueue.main.async {
      if let e = err { return completion(.failure(e)) }
      guard let d = data else { return completion(.failure(JoinGroupError.noData)) }
      do {
        let ag = try JSONDecoder().decode(ActiveGroup.self, from: d)
        completion(.success(ag))
      } catch {
        completion(.failure(error))
      }
    }
  }.resume()
}
#endif
