//
//  LandingPage.swift
//  tag-along
//
//  Created by Havish Komatreddy on 8/3/25.
//

import SwiftUI
import MapKit

struct OnboardingView: View {
    @EnvironmentObject var router: Router
    // If you want the real map, uncomment these lines and remove the gray box below
    /*
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    */
    
    // for a real paging control later
    @State private var pageIndex: Int = 0
    
    // your custom colors
    private let background = Color(hex: "#F9F9F6")
    private let button = Color(hex: "#7E8383")
    
    private let primaryGreen = Color(red:  7/255,   green:  70/255,  blue:  47/255)
    private let accentTan    = Color(red:196/255,   green:164/255,  blue:132/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Top “map” area
            ZStack {
                // real map:
                /*
                Map(coordinateRegion: $region)
                    .ignoresSafeArea(edges: .top)
                */
                
                // placeholder gray box
                Rectangle()
                    .fill(Color(background))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                Text("Put a map here")
                    .foregroundColor(primaryGreen)
            }
            
            Spacer(minLength: 40)
            
            // Page-control dotsx
            HStack(spacing: 12) {
                ForEach(0..<3) { idx in
                    Circle()
                        .fill(idx == pageIndex ? accentTan : Color(.tertiaryLabel))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom, 24)
            .padding(.trailing, 300)
            
            // Title + subtitle
            VStack(spacing: 12) {
                Text("Welcome to Tag-Along")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(primaryGreen)
                    .padding(.bottom,20)
                
                Text("Get started today with the most private location service")
                    .font(.system(size:  16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal,  30)
                    .padding(.bottom, 49)
            }
            
            Spacer()
            
            // Next button
            Button(action: {
                // advance to next page / onboarding step
                router.route = .signupHome
            }) {
                Text("Next")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height:  50)
                    .background(Color(button))
                    .foregroundColor(.white)
                    .cornerRadius( 15)
            }
            .padding(.horizontal,  20)
        }
        .ignoresSafeArea(edges: .top)
    }
}
