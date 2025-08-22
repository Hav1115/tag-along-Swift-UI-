// This file is no longer needed with NavigationLink-based navigation everywhere. You can remove ContentView.swift.

import SwiftUI

struct ContentView: View {
    @StateObject private var router = Router()
    
    var body: some View {
        switch router.route {
        case .signupHome:
            SignUpView().environmentObject(router)
        case .signupemail:
            EmailSignUpView().environmentObject(router)
        case .userPrompt(let email):
            UserPromptView(email: email).environmentObject(router)
        case .home:
            HomePage().environmentObject(router)
        case .googleSignup:
            GoogleAuthView().environmentObject(router)
        case .appleSignup:
            AppleAuthView().environmentObject(router)
        case .login:
            Loginpage().environmentObject(router)
        case .emailLogin:
            EmailLogin().environmentObject(router)
        case .creategroup:
            CreateGroup().environmentObject(router)
        case .joingroup:
            JoinGroupView().environmentObject(router)
        case .viewGroup:
            ViewActiveGroups().environmentObject(router)
        case .groupDetail(let code):
            GroupDetailView(groupCode: code).environmentObject(router)
        case .land:
            OnboardingView().environmentObject(router)
        case .duckwalk:
            DuckWalkAnimationView().environmentObject(router)
        case .tabs(let start):
                    MainTabView(startTab: start)
                        .environmentObject(router)
        }
    }
}
