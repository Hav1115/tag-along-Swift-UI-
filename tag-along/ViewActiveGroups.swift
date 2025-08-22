import SwiftUI

struct ViewActiveGroups: View {
    @EnvironmentObject var router: Router
    @State private var activeGroup: GroupOut? = nil
    @State private var isLoading = false
    @State private var resultMessage = ""
    @AppStorage("userEmail") private var userEmail: String = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { router.route = .home }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.top)

            Text("Active Group")
                .font(.title)
                .bold()

            if isLoading {
                ProgressView()
            } else if let group = activeGroup {
                VStack(spacing: 12) {
                    Text("Group Code: \(group.groupCode)")
                        .font(.headline)
                    if let name = group.groupName {
                        Text("Group Name: \(name)")
                    }
                    Divider()
                    Text("Members:")
                        .font(.subheadline)
                    ForEach(group.members, id: \.self) { member in
                        Text(member)
                    }
                    if let expires = group.expiresAt {
                        Text("Expires: \(expires.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text(resultMessage.isEmpty ? "No active group found." : resultMessage)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .onAppear(perform: fetchActiveGroup)
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }

    func fetchActiveGroup() {
        guard !userEmail.isEmpty,
              let url = URL(string: "http://192.168.86.248:8000/users/\(userEmail)/active-group") else {
            resultMessage = "User email not set."
            return
        }
        isLoading = true
        resultMessage = ""
        URLSession.shared.dataTask(with: url) { data, _, error in
            Task { @MainActor in
                isLoading = false
                if let error = error {
                    resultMessage = "Error: \(error.localizedDescription)"
                    return
                }
                guard let data = data,
                      let groupOut = try? JSONDecoder().decode(GroupOut.self, from: data) else {
                    resultMessage = "No active group found."
                    return
                }
                activeGroup = groupOut
            }
        }.resume()
    }
} 
