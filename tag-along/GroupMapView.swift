//
//  GroupMapView.swift
//  tag-along
//
//  Created by Havish Komatreddy on 7/18/25.
//

import SwiftUI
import MapKit
import CoreLocation

private struct ProximityState {
  var lastNotificationTime: Date? = nil          // When we last fired an alert
  var hasAllReturnedSinceNotification: Bool = true // Whether everyone’s back in range since then
}
struct GroupMapView: View {
    let groupCode: String
    @AppStorage("username") private var username: String = ""
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var locationService = LocationService()
    
    @State private var groupLocations: [UserLocationData] = []
    @State private var proximityState = ProximityState()
    private let thresholdMeters: CLLocationDistance = 0
    private let cooldownSeconds: TimeInterval = 25 * 60
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Default to 0,0 instead of SF
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var isLocationSharingEnabled = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hasInitializedMap = false
    
    // Timer for periodic location updates
    @State private var locationUpdateTimer: Timer?
    @State private var fetchTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack {
                // 1️⃣ Your toggle
                HStack {
                    Toggle("Share Location", isOn: $isLocationSharingEnabled)
                        .onChange(of: isLocationSharingEnabled) {
                          if    isLocationSharingEnabled {
                            startLocationSharing()
                          } else {
                            stopLocationSharing()
                          }
                        }
                    Spacer()
                    Text("\(groupLocations.count) of ? sharing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // 2️⃣ Just the map here, no lifecycle modifiers
                mapView
                
                // 3️⃣ Your location info
                if let userLocation = groupLocations.first(where: { $0.username == username }) {
                    locationInfoView(for: userLocation)
                }
            }
            .navigationTitle("Group Map")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Location Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            
            // ← ALL of your “view appeared / auth changed / view disappeared” logic here:
            .onAppear {
                // ask once
                locationManager.requestLocationPermission()
                // if toggle was already on, start right now
                if isLocationSharingEnabled {
                    startLocationSharing()
                }
                // begin fetching group pins
                startFetchingLocations()
            }
            .onChange(of: locationManager.authorizationStatus) {
              let s = locationManager.authorizationStatus
              if isLocationSharingEnabled,
                 (s == .authorizedWhenInUse || s == .authorizedAlways) {
                startLocationSharing()
              }
            }
            .onDisappear {
                // clean up timers & updates
                stopAllUpdates()
            }
        }
    }

    
    // Initialize map with user's current location or group locations
     func initializeMapLocation() {
        guard !hasInitializedMap, !groupLocations.isEmpty else { return }
        updateMapRegion(paddingFactor: 1.5)      // fit to all members, with 50% extra space
        hasInitializedMap = true
    }
    
    // Separate computed properties
     var mapView: some View {
        Map {
            ForEach(groupLocations, id: \.username) { location in
                Annotation(location.username, coordinate: location.coordinate) {
                    LocationAnnotationView(
                        username: location.username,
                        isCurrentUser: location.username == username,
                        lastUpdated: location.lastUpdatedDate
                    )
                }
            }
            
            // Show user location
            UserAnnotation()
        }
        .onReceive(locationManager.$location) { location in
            // Update map region when user location changes (only if not initialized with group data)
            if let location = location, !hasInitializedMap {
                mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                )
                hasInitializedMap = true
            }
        }
    }

     func locationInfoView(for userLocation: UserLocationData) -> some View {
        VStack(alignment: .leading) {
            Text("Your Location")
                .font(.headline)
            Text("Lat: \(userLocation.latitude, specifier: "%.6f")")
            Text("Lng: \(userLocation.longitude, specifier: "%.6f")")
            if let lastUpdated = userLocation.lastUpdatedDate {
                Text("Updated: \(lastUpdated, style: .time)")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    func startLocationSharing() {
        // Remove the immediate return - let the delegate handle permission changes
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Start updates immediately if already authorized
            locationManager.startLocationUpdates()
            startLocationUpdateTimer()
        case .notDetermined:
            // Request permission - the delegate will handle starting updates
            locationManager.requestLocationPermission()
        case .denied, .restricted:
            locationManager.locationError = "Location access denied. Please enable in Settings."
            isLocationSharingEnabled = false
        @unknown default:
            break
        }
    }
    
    func startLocationUpdateTimer() {
        // Send initial location immediately if available
        if locationManager.location != nil {
            sendLocationUpdate()
        }
        
        // Start timer for periodic updates
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.sendLocationUpdate()
        }
    }
    
    func stopLocationSharing() {
        locationManager.stopLocationUpdates()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        
        // Remove user's location from server
        Task {
            try await locationService.deleteLocation(username: username, groupCode: groupCode)
        }
    }
    
     func startFetchingLocations() {
        fetchGroupLocations()
        
        // Start timer to fetch locations every 10 seconds (matching your request)
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            fetchGroupLocations()
        }
    }
    
     func stopAllUpdates() {
        locationUpdateTimer?.invalidate()
        fetchTimer?.invalidate()
        locationUpdateTimer = nil
        fetchTimer = nil
    }
    
    private func sendLocationUpdate() {
        // 1️⃣ Don’t even try if sharing is off
        guard isLocationSharingEnabled else { return }
        // 2️⃣ Make sure we have a GPS fix
        guard let loc = locationManager.location else { return }

        // 3️⃣ Build the request payload
        let req = LocationUpdateRequest(
            username:          username,
            group_code:        groupCode,
            latitude:          loc.coordinate.latitude,
            longitude:         loc.coordinate.longitude,
            accuracy:          loc.horizontalAccuracy,
            timestamp:         ISO8601DateFormatter().string(from: loc.timestamp),
            is_sharing_enabled: true    // reflect your toggle
        )

        // 4️⃣ Fire it off
        Task {
            do {
                try await locationService.updateLocation(request: req)
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to update location: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    func fetchGroupLocations() {
        Task {
            do {
                let response = try await locationService.getGroupLocations(groupCode: groupCode)
//                print("✅ Got GroupLocationsResponse:", response)
//                            for loc in response.locations {
//                                print("   • \(loc.username): \(loc.latitude), \(loc.longitude) (lastUpdated: \(loc.last_updated))")
//                            }
//                            print("   total_members:", response.total_members,
//                                  "active_locations:", response.active_locations)
                DispatchQueue.main.async {
                    groupLocations = response.locations
                    initializeMapLocation()
                    // Update map region to show all locations (but don't override user's manual panning)
                    if !hasInitializedMap || groupLocations.count == 1 {
                        updateMapRegion()
                    }
                    checkProximity()
                }
            } catch {
                print("Failed to fetch group locations: \(error)")
            }
        }
    }
    
     func updateMapRegion(paddingFactor: Double = 1.2) {
        guard !groupLocations.isEmpty else { return }
        
        let coords = groupLocations.map(\.coordinate)
        let latitudes  = coords.map(\.latitude)
        let longitudes = coords.map(\.longitude)
        
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!
        
        let center = CLLocationCoordinate2D(
            latitude:  (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta:  (maxLat - minLat) * paddingFactor,
            longitudeDelta: (maxLon - minLon) * paddingFactor
        )
        
        mapRegion = MKCoordinateRegion(center: center, span: span)
    }
    
    func checkProximity() {
            guard let me = groupLocations.first(where: { $0.username == username }) else { return }
            let now = Date()
            let others = groupLocations.filter { $0.username != username }
            // Identify those beyond threshold
            let outOfRange = others.filter {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                    .distance(from: CLLocation(latitude: me.latitude, longitude: me.longitude)) > thresholdMeters
            }

            if !outOfRange.isEmpty {
                let canNotify: Bool
                if let last = proximityState.lastNotificationTime {
                    canNotify = proximityState.hasAllReturnedSinceNotification && now.timeIntervalSince(last) >= cooldownSeconds
                } else {
                    canNotify = true
                }
                if canNotify {
                    let names = outOfRange.map(\.username)
                    print("🔔 [checkProximity] Out‑of‑range: \(names), canNotify=\(canNotify)")
                    sendOutOfRangeNotification(names: names)
                    proximityState.lastNotificationTime = now
                    proximityState.hasAllReturnedSinceNotification = false
                }
            } else {
                proximityState.hasAllReturnedSinceNotification = true
            }
        }
     func sendOutOfRangeNotification(names: [String]) {
            print("🔔 [sendOutOfRangeNotification] Sending notification for: \(names)")
            let content = UNMutableNotificationContent()
            if names.count == 1 {
                content.body = "\(names[0]) has walked a little far away."
            } else {
                let list = names.joined(separator: " and ")
                content.body = "\(list) are a little far away."
            }
            content.sound = .default
            // Immediate delivery
            let req = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
            UNUserNotificationCenter.current().add(req)
        }
}


struct LocationAnnotationView: View {
    let username: String
    let isCurrentUser: Bool
    let lastUpdated: Date?
    
    var body: some View {
        VStack {
            // Pin
            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.blue : Color.red)
                    .frame(width: 20, height: 20)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                
                if isCurrentUser {
                    Image(systemName: "person.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                } else {
                    Text(String(username.prefix(1)).uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            
            // Username label
            Text(username)
                .font(.caption)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Usage in your existing app structure
struct GroupDetailView: View {
    @EnvironmentObject var router: Router
    let groupCode: String
    @State private var showMap = false
    
    var body: some View {
        VStack {
            // Your existing group detail content
            HStack {
                    Button { router.route = .home } label: {
                      Label("Back", systemImage: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                  }
                  .padding(.top)

            
            Button("View Map") {
                showMap = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showMap) {
            GroupMapView(groupCode: groupCode)
        }
    }
}

