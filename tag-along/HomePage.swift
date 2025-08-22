//import SwiftUI
//
//struct HomePage: View {
//    @EnvironmentObject var router: Router
//    private let locationService = LocationService()
//    @State private var showAlert = false
//    @State private var alertMsg = ""
//    @AppStorage("username") private var username = ""
//    var body: some View {
//        VStack(spacing: 20) {
//            HStack {
//                // Logout button
//                Button(action: logout) {
//                    HStack(spacing: 4) {
//                        Image(systemName: "power")
//                        Text("Logout")
//                    }
//                }
//                .buttonStyle(.bordered)
//                .foregroundColor(.red)
//            }
//            .padding(.top)
//            
//            Text("Welcome!")
//                .font(.title2)
//                .padding()
//            
//            Button("Join Group") {
//                router.route = .joingroup
//            }
//            .buttonStyle(.borderedProminent)
//            
//            Button("Create Group") {
//                router.route = .creategroup
//            }
//            .buttonStyle(.borderedProminent)
//            
//            Button("Go To My Group") {
//                Task {
//                    do {
//                        let resp = try await locationService.getActiveGroup(for: username)
//                        if resp.success, let code = resp.group_code {
//                            // ← HERE is your groupCodex
//                            router.route = .groupDetail(groupCode: code)
//                        } else {
//                            alertMsg = resp.message ?? "No active group"
//                            showAlert = true
//                        }
//                    } catch {
//                        alertMsg = error.localizedDescription
//                        showAlert = true
//                    }
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .alert("Oops", isPresented: $showAlert) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(alertMsg)
//            }
//            
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("")
//        .padding()
//        .navigationBarBackButtonHidden(true)
//    }
//    private func logout() {
//        // Simply navigate back to signup - no persistent data to clear
//        UserDefaults.standard.set("", forKey: "email")
//        UserDefaults.standard.set("", forKey: "username")
//        router.route = .signupHome
//    }
//}



// *****************************************************NEW ONE ***************************************************************************

import SwiftUI

struct HomePage: View {
    @EnvironmentObject var groupVM: GroupViewModel   // <- shared VM from MainTabView

    // theme
    private let bgColor      = Color(hex: "#F7F7F2")
    private let outlineGray  = Color(hex: "#E5E5EA")
    private let tanBorder    = Color(hex: "#C4A78B")
    private let primaryGreen = Color(hex: "#07462F")
    private let bottom       = Color(hex: "#B7A395")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if let g = groupVM.currentGroup {
                // ✅ already in a group
                InGroupHome()
                    .transition(.opacity)
            } else {
                // ❌ not in a group (your current duck screen)
                NotInGroupLanding(primaryGreen: primaryGreen, bgColor: bgColor)
                    .transition(.opacity)
            }
        }
        // refresh membership when Home appears / pull to refresh
        .task { if groupVM.currentGroup == nil { groupVM.checkForActiveGroup() } }
        .refreshable { groupVM.checkForActiveGroup() }
    }
}

private struct NotInGroupLanding: View {
    let primaryGreen: Color
    let bgColor: Color
    var body: some View {
        VStack {
            Spacer(minLength: 80)

            Text("duck duck......")
                .font(.custom("Schoolbell-Regular", size: 44))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(primaryGreen)

            Image("Duckonbook")
                .resizable()
                .scaledToFit()
                .frame(width: 500, height: 450)
                .padding(.top, -10)
                .padding(.leading, 70)

            Text("Sorry you haven’t joined any groups yet")
                .font(.custom("Schoolbell-Regular", size: 20))
                .multilineTextAlignment(.center)
                .padding(.bottom, 150)

            Spacer()
        }
    }
}

struct InGroupHome: View {
    @EnvironmentObject var groupVM: GroupViewModel

    private let primaryGreen = Color(hex: "#07462F")
    private let tanBorder    = Color(hex: "#C4A78B")
    private let bgColor      = Color(hex: "#F7F7F2")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if let g = groupVM.currentGroup {
                VStack(spacing: 24) {
                    // Title = group name
                    Text(g.name.isEmpty ? "Group" : g.name)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(primaryGreen)
                        .padding(.top, 12)

                    // Timer chip
                    Text(timeString(from: g.timeRemaining))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(primaryGreen)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(tanBorder, lineWidth: 5)
                        )

                    // Map embedded below the chip
                    GroupMapView(groupCode: g.code)      // ⬅️ no sheet; inline
                        .id(g.code)                      // refresh map if group changes
                        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(tanBorder, lineWidth: 3)
                        )
                        .padding(.horizontal, 20)

                    Spacer()
                }
            }
        }
        .task { if groupVM.currentGroup == nil { groupVM.checkForActiveGroup() } }
    }

    private func timeString(from seconds: Int) -> String {
        let mins = max(0, seconds / 60)
        return "\(mins / 60) hr \(mins % 60) min"
    }
}
