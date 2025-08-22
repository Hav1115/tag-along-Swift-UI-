//import Foundation
//import SwiftUI
//
//class GroupViewModel: ObservableObject {
//    // Base URL for API calls
//    let baseURL = "http://192.168.86.70:8000"
//    
//    @Published var groupName: String = ""
//    @Published var selectedMinutes: Int = 15
//    @Published var currentGroup: GroupDetails?
//    @Published var errorMessage: String?
//    @Published var isLoading: Bool = false
//    @Published var showError: Bool = false
//    
//    // Time intervals for the picker (15-60 minutes in 15-minute intervals)
//    let timeIntervals = Array(stride(from: 15, through: 60, by: 15))
//    
//    // Timer for updating the countdown
//    private var timer: Timer?
//    
//    init() {
//        checkForActiveGroup()
//    }
//    
//    func createGroup() {
//        print("🟢 createGroup called")
//        
//        guard !groupName.isEmpty else {
//            errorMessage = "Please enter a group name"
//            showError = true
//            return
//        }
//        
//        isLoading = true
//        errorMessage = nil
//        
//        guard let username = UserDefaults.standard.string(forKey: "username") else {
//            print("🟢 No username in UserDefaults")
//            errorMessage = "Username not found"
//            showError = true
//            isLoading = false
//            return
//        }
//        
//        print("🟢 Creating group '\(groupName)' for user '\(username)'")
//        
//        let request = CreateGroupRequest(
//            group_name: groupName,
//            expiration_minutes: selectedMinutes,
//            creator_username: username
//        )
//        
//        guard let url = URL(string: "\(baseURL)/groups/create") else {
//            print("🟢 Invalid URL")
//            return
//        }
//        
//        print("🟢 URL: \(url)")
//        
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        do {
//            urlRequest.httpBody = try JSONEncoder().encode(request)
//            if let data = urlRequest.httpBody, let jsonString = String(data: data, encoding: .utf8) {
//                print("🟢 CreateGroup JSON: \(jsonString)")
//            }
//        } catch {
//            print("🟢 Failed to encode request: \(error)")
//            errorMessage = "Failed to encode request"
//            showError = true
//            isLoading = false
//            return
//        }
//        
//        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                
//                if let error = error {
//                    print("🟢 Network error: \(error)")
//                    self?.errorMessage = error.localizedDescription
//                    self?.showError = true
//                    return
//                }
//                
//                if let httpResponse = response as? HTTPURLResponse {
//                    print("🟢 HTTP Status Code: \(httpResponse.statusCode)")
//                    
//                    if !(200...299).contains(httpResponse.statusCode) {
//                        self?.errorMessage = "Server error: \(httpResponse.statusCode)"
//                        self?.showError = true
//                        return
//                    }
//                }
//                
//                guard let data = data else {
//                    print("🟢 No data received")
//                    self?.errorMessage = "No data received"
//                    self?.showError = true
//                    return
//                }
//                
//                if let rawString = String(data: data, encoding: .utf8) {
//                    print("🟢 Raw response: \(rawString)")
//                }
//                
//                do {
//                    let response = try JSONDecoder().decode(GroupResponse.self, from: data)
//                    print("🟢 Decoded response successfully")
//                    if response.success {
//                        if let groupDetails = GroupDetails.from(response) {
//                            print("🟢 Group created successfully")
//                            self?.currentGroup = groupDetails
//                            self?.startTimer()
//                        } else {
//                            print("🟢 Failed to create GroupDetails from response")
//                            self?.errorMessage = "Invalid group expiration time"
//                            self?.showError = true
//                        }
//                    } else {
//                        print("🟢 Backend returned success=false: \(response.message ?? "No message")")
//                        self?.errorMessage = response.message ?? "Failed to create group"
//                        self?.showError = true
//                    }
//                } catch {
//                    print("🟢 Failed to decode response: \(error)")
//                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
//                    self?.showError = true
//                }
//            }
//        }.resume()
//    }
//    
//    func checkForActiveGroup() {
//        guard let username = UserDefaults.standard.string(forKey: "username") else { return }
//        
//        guard let url = URL(string: "\(baseURL)/users/\(username)/active-group") else { return }
//        
//        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
//            DispatchQueue.main.async {
//                guard let data = data else { return }
//                
//                do {
//                    let response = try JSONDecoder().decode(GroupResponse.self, from: data)
//                    if response.success {
//                        if let groupDetails = GroupDetails.from(response) {
//                            self?.currentGroup = groupDetails
//                            self?.startTimer()
//                        }
//                    }
//                } catch {
//                    print("Failed to decode active group: \(error)")
//                }
//            }
//        }.resume()
//    }
//    
//    func cancelGroup() {
//        print("🔴 cancelGroup called")
//        
//        guard let groupCode = currentGroup?.code else {
//            print("🔴 No group code available")
//            return
//        }
//        
//        guard let email = UserDefaults.standard.string(forKey: "email") else {
//            print("🔴 No email in UserDefaults")
//            errorMessage = "Email not found. Please log in again."
//            showError = true
//            return
//        }
//        
//        print("🔴 Attempting to end group: \(groupCode) for user: \(email)")
//        
//        guard let url = URL(string: "\(baseURL)/groups/\(groupCode)/end") else {
//            print("🔴 Invalid URL")
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body = ["user_email": email]
//        
//        do {
//            request.httpBody = try JSONEncoder().encode(body)
//            if let requestBody = String(data: request.httpBody!, encoding: .utf8) {
//                print("🔴 End group request body: \(requestBody)")
//            }
//        } catch {
//            print("🔴 Failed to encode request: \(error)")
//            errorMessage = "Failed to encode request"
//            showError = true
//            return
//        }
//        
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("🔴 Network error: \(error)")
//                    self?.errorMessage = "Network error: \(error.localizedDescription)"
//                    self?.showError = true
//                    return
//                }
//                
//                if let httpResponse = response as? HTTPURLResponse {
//                    print("🔴 HTTP Status Code: \(httpResponse.statusCode)")
//                    
//                    if httpResponse.statusCode != 200 {
//                        self?.errorMessage = "Server error: \(httpResponse.statusCode)"
//                        self?.showError = true
//                        return
//                    }
//                }
//                
//                guard let data = data else {
//                    print("🔴 No data received from server")
//                    self?.errorMessage = "No response from server"
//                    self?.showError = true
//                    return
//                }
//                
//                if let rawString = String(data: data, encoding: .utf8) {
//                    print("🔴 End group raw response: \(rawString)")
//                }
//                
//                // Check if response is empty
//                if data.isEmpty {
//                    print("🔴 Response data is empty")
//                    self?.errorMessage = "Empty response from server"
//                    self?.showError = true
//                    return
//                }
//                
//                do {
//                    let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
//                    print("🔴 Decoded response: success=\(response.success), message=\(response.message ?? "nil")")
//                    if response.success {
//                        print("🔴 Group ended successfully - clearing currentGroup")
//                        self?.currentGroup = nil
//                        self?.stopTimer()
//                    } else {
//                        print("🔴 Backend returned error: \(response.message ?? "Unknown error")")
//                        self?.errorMessage = response.message ?? "Failed to end group"
//                        self?.showError = true
//                    }
//                } catch {
//                    print("🔴 Failed to decode end group response: \(error)")
//                    print("🔴 Data length: \(data.count)")
//                    if let jsonString = String(data: data, encoding: .utf8) {
//                        print("🔴 Raw JSON: \(jsonString)")
//                    }
//                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
//                    self?.showError = true
//                }
//            }
//        }.resume()
//    }
//    
//    private func startTimer() {
//        stopTimer()
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//            self?.updateTimeRemaining()
//        }
//    }
//    
//    private func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//    
//    private func updateTimeRemaining() {
//        guard var group = currentGroup else {
//            stopTimer()
//            return
//        }
//        
//        let remaining = Int(group.expiresAt.timeIntervalSinceNow)
//        if remaining <= 0 {
//            currentGroup = nil
//            stopTimer()
//        } else {
//            group.timeRemaining = remaining
//            currentGroup = group
//        }
//    }
//    
//    deinit {
//        stopTimer()
//    }
//}


import Foundation
import SwiftUI

class GroupViewModel: ObservableObject {

    @Published var groupName: String = ""
    @Published var selectedMinutes: Int = 60          // default 1 hr (slider)
    @Published var currentGroup: GroupDetails?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false

    private var timer: Timer?

    init() {
        checkForActiveGroup()
    }

    func createGroup() {
        selectedMinutes = min(max(selectedMinutes, 60), 1440) // clamp 1–24h

        guard !groupName.isEmpty else {
            errorMessage = "Please enter a group name"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        guard let username = UserDefaults.standard.string(forKey: "username") else {
            errorMessage = "Username not found"
            showError = true
            isLoading = false
            return
        }

        let request = CreateGroupRequest(
            group_name: groupName,
            expiration_minutes: selectedMinutes,
            creator_username: username
        )

        guard let url = URL(string: "\(baseURL)/groups/create") else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do { urlRequest.httpBody = try JSONEncoder().encode(request) }
        catch {
            errorMessage = "Failed to encode request"
            showError = true
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                    return
                }

                if let http = response as? HTTPURLResponse,
                   !(200...299).contains(http.statusCode) {
                    self?.errorMessage = "Server error: \(http.statusCode)"
                    self?.showError = true
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    self?.showError = true
                    return
                }

                do {
                    let resp = try JSONDecoder().decode(GroupResponse.self, from: data)
                    if resp.success, let details = GroupDetails.from(resp) {
                        self?.currentGroup = details
                        self?.startTimer()
                    } else {
                        self?.errorMessage = resp.message ?? "Failed to create group"
                        self?.showError = true
                    }
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    self?.showError = true
                }
            }
        }.resume()
    }

    func checkForActiveGroup() {
        guard let username = UserDefaults.standard.string(forKey: "username"),
              let url = URL(string: "\(baseURL)/users/\(username)/active-group") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else { return }
                do {
                    let resp = try JSONDecoder().decode(GroupResponse.self, from: data)
                    if resp.success, let details = GroupDetails.from(resp) {
                        self?.currentGroup = details
                        self?.startTimer()
                    }
                } catch {
                    print("Failed to decode active group: \(error)")
                }
            }
        }.resume()
    }

    func cancelGroup() {
        guard let code = currentGroup?.code else { return }
        guard let email = UserDefaults.standard.string(forKey: "email") else {
            errorMessage = "Email not found. Please log in again."
            showError = true
            return
        }

        guard let url = URL(string: "\(baseURL)/groups/\(code)/end") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["user_email": email]
        req.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    self?.showError = true
                    return
                }

                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    self?.errorMessage = "Server error: \(http.statusCode)"
                    self?.showError = true
                    return
                }

                guard let data = data, !data.isEmpty else {
                    self?.errorMessage = "Empty response from server"
                    self?.showError = true
                    return
                }

                do {
                    let resp = try JSONDecoder().decode(SimpleResponse.self, from: data)
                    if resp.success {
                        self?.currentGroup = nil
                        self?.stopTimer()
                    } else {
                        self?.errorMessage = resp.message ?? "Failed to end group"
                        self?.showError = true
                    }
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    self?.showError = true
                }
            }
        }.resume()
    }

    // countdown timer
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimeRemaining()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimeRemaining() {
        guard var group = currentGroup else {
            stopTimer()
            return
        }
        let remaining = Int(group.expiresAt.timeIntervalSinceNow)
        if remaining <= 0 {
            currentGroup = nil
            stopTimer()
        } else {
            group.timeRemaining = remaining
            currentGroup = group
        }
    }

    deinit { stopTimer() }
}
