//
//  MainTabView.swift.swift
//  tag-along
//
//  Created by Havish Komatreddy on 8/7/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var router: Router
    @State private var selection: Int
    @State private var loadingActive = true

    private let primaryGreen = Color(hex: "#07462F")
    private let bottom       = Color(hex: "#B7A395")

    init(startTab: Int = 0) {
        _selection = State(initialValue: startTab)

        // iOS 15+ appearance
        let ap = UITabBarAppearance()
        ap.configureWithOpaqueBackground()
        ap.backgroundColor = UIColor(bottom)
        ap.shadowColor = UIColor.black.withAlphaComponent(0.08)

        ap.stackedLayoutAppearance.normal.iconColor  = UIColor(primaryGreen).withAlphaComponent(0.6)
        ap.stackedLayoutAppearance.selected.iconColor = UIColor(primaryGreen)
        UITabBar.appearance().standardAppearance = ap
        UITabBar.appearance().scrollEdgeAppearance = ap
        UITabBar.appearance().tintColor = UIColor(primaryGreen)
        UITabBar.appearance().unselectedItemTintColor = UIColor(primaryGreen).withAlphaComponent(0.6)
        
    }


    var body: some View {
        TabView(selection: $selection) {

            // HOME = duck screen
            NavigationStack {
                HomePage()                     // << your duck view here
            }
            .tabItem { Image(systemName: "house"); Text("Home") }
            .tag(0)

            // HISTORY
            NavigationStack { Text("History").navigationTitle("History") }
                .tabItem { Image(systemName: "map"); Text("History") }
                .tag(1)

            // JOIN / CREATE (use your existing join/create screens here)
            NavigationStack {
                JoinCreateLanding()
            }
            .tabItem { Image(systemName: "plus.circle"); Text("Join/Create") }
            .tag(2)

            // FRIENDS
            NavigationStack { Text("Friends").navigationTitle("Friends") }
                .tabItem { Image(systemName: "person.2"); Text("Friends") }
                .tag(3)

            // ACCOUNT
            NavigationStack { AccountScreen().navigationTitle("Account") }
                .tabItem { Image(systemName: "person.circle"); Text("Account") }
                .tag(4)
        }
        .tint(primaryGreen)
        .toolbarBackground(bottom, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
