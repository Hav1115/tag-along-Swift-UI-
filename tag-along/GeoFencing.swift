//
//  GeoFencing.swift
//  tag-along
//
//  Created by Havish Komatreddy on 7/24/25.
//

//
//  GeofenceModels.swift
//  tag-along
//

import Foundation
import CoreLocation

// MARK: - Geofence Data Models
struct GeofenceCreateRequest: Codable {
    let group_code: String
    let creator_username: String
    let center_latitude: Double
    let center_longitude: Double
    let radius_meters: Double
    let geofence_name: String
    let follow_creator: Bool
}

private struct MapPin: Identifiable {
  enum Kind { case selected, user }
  let id = UUID()
  let kind: Kind
  let coordinate: CLLocationCoordinate2D
}

struct AnnotationItem: Identifiable {
  let id: String
  let coordinate: CLLocationCoordinate2D
}

struct GeofenceResponse: Codable {
    let success: Bool
    let geofence: GeofenceData?
    let message: String?
}

struct GeofenceData: Codable, Identifiable {
    var id: String { group_code }
    let group_code: String
    let geofence_name: String
    let center_latitude: Double
    let center_longitude: Double
    let radius_meters: Double
    let follow_creator: Bool
    let is_active: Bool
    let created_at: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: center_latitude, longitude: center_longitude)
    }
    
    var radiusInKilometers: Double {
        radius_meters / 1000.0
    }
}

struct GeofenceAlert: Codable, Identifiable {
    var id: String { "\(username)-\(timestamp)" }
    let username: String
    let alert_type: String // "entered" or "exited"
    let geofence_name: String
    let timestamp: String
    let user_latitude: Double
    let user_longitude: Double
    let is_read: Bool
    
    var alertDate: Date? {
        ISO8601DateFormatter().date(from: timestamp)
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: user_latitude, longitude: user_longitude)
    }
}

struct GeofenceAlertsResponse: Codable {
    let group_code: String
    let alerts: [GeofenceAlert]
    let total_alerts: Int
}

// MARK: - Geofence Service
extension LocationService {
    func createGeofence(request: GeofenceCreateRequest) async throws -> GeofenceResponse {
        guard let url = URL(string: "\(baseURL)/geofences/create") else {
            throw LocationError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw LocationError.serverError
        }
        
        return try JSONDecoder().decode(GeofenceResponse.self, from: data)
    }
    
    func getGeofence(groupCode: String) async throws -> GeofenceResponse {
        guard let url = URL(string: "\(baseURL)/geofences/\(groupCode)") else {
            throw LocationError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LocationError.serverError
        }
        
        return try JSONDecoder().decode(GeofenceResponse.self, from: data)
    }
    
    func deleteGeofence(groupCode: String, creatorUsername: String) async throws {
        guard let url = URL(string: "\(baseURL)/geofences/\(groupCode)") else {
            throw LocationError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["creator_username": creatorUsername]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw LocationError.serverError
        }
    }
    
    func getGeofenceAlerts(groupCode: String, limit: Int = 50) async throws -> GeofenceAlertsResponse {
        guard let url = URL(string: "\(baseURL)/groups/\(groupCode)/geofence-alerts?limit=\(limit)") else {
            throw LocationError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LocationError.serverError
        }
        
        return try JSONDecoder().decode(GeofenceAlertsResponse.self, from: data)
    }
}

//
//  GeofenceSetupView.swift
//  tag-along
//

import SwiftUI
import MapKit

struct GeofenceSetupView: View {
    let groupCode: String
    @AppStorage("username") private var username: String = ""
    @StateObject private var locationService = LocationService()
    @StateObject private var locationManager = LocationManager()
    
    @State private var geofenceName = "Safe Zone"
    @State private var radiusMeters: Double = 500
    @State private var followCreator = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var isCreating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    // Map region
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    )
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("Geofence Settings") {
                        TextField("Geofence Name", text: $geofenceName)
                        
                        VStack(alignment: .leading) {
                            Text("Radius: \(Int(radiusMeters))m")
                            Slider(value: $radiusMeters, in: 50...2000, step: 50)
                        }
                        
                        Toggle("Follow My Location", isOn: $followCreator)
                            .help("If enabled, the geofence will move with you")
                    }
                    
                    Section("Location") {
                        if followCreator {
                            Text("Geofence will follow your location")
                                .foregroundColor(.secondary)
                        } else {
                            Button("Use Current Location") {
                                useCurrentLocation()
                            }
                            .disabled(locationManager.location == nil)
                            
                            if let selected = selectedLocation {
                                Text("Selected: \(selected.latitude, specifier: "%.4f"), \(selected.longitude, specifier: "%.4f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                // Map for location selection
                if !followCreator {
                    mapSelectionView
                        .frame(minHeight: 200)
                }
                
                Spacer()
                
                // Create button
                Button(action: createGeofence) {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Create Geofence")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreating || (!followCreator && selectedLocation == nil))
                .padding()
            }
            .navigationTitle("Create Geofence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Geofence Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                locationManager.requestLocationPermission()
                if let userLocation = locationManager.location {
                    mapRegion.center = userLocation.coordinate
                    selectedLocation = userLocation.coordinate
                }
            }
        }
    }
    
    private var pins: [MapPin] {
      var p = [MapPin]()
      if let sel = selectedLocation {
        p.append(.init(kind: .selected, coordinate: sel))
      }
      if let loc = locationManager.location {
        p.append(.init(kind: .user, coordinate: loc.coordinate))
      }
      return p
    }
    
    private var mapSelectionView: some View {
      Map(
        coordinateRegion: $mapRegion,
        interactionModes: .all,
        annotationItems: pins      // ← here!
      ) { pin in                  // ← closure must take one argument
        MapAnnotation(coordinate: pin.coordinate) {
          if pin.kind == .selected {
            ZStack {
              Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: radiusVisualization, height: radiusVisualization)
              Circle().fill(Color.blue).frame(width: 20, height: 20)
              Circle().fill(Color.white).frame(width: 12, height: 12)
            }
          } else {
            Circle()
              .fill(Color.green)
              .frame(width: 16, height: 16)
              .overlay(Circle().stroke(Color.white, lineWidth: 2))
          }
        }
      }
      .onTapGesture(coordinateSpace: .local) { location in
        // your tap‑to‑coordinate code
      }
    }
            
    
    private var radiusVisualization: CGFloat {
        // Approximate visualization of radius on map
        let metersPerPoint = mapRegion.span.latitudeDelta * 111000 / 200 // rough calculation
        return CGFloat(radiusMeters / metersPerPoint) * 2
    }
    
    private func useCurrentLocation() {
        guard let location = locationManager.location else { return }
        selectedLocation = location.coordinate
        mapRegion.center = location.coordinate
    }
    
    private func createGeofence() {
        isCreating = true
        
        let centerCoordinate: CLLocationCoordinate2D
        if followCreator {
            guard let userLocation = locationManager.location else {
                alertMessage = "Cannot get your current location"
                showAlert = true
                isCreating = false
                return
            }
            centerCoordinate = userLocation.coordinate
        } else {
            guard let selectedLocation = selectedLocation else {
                alertMessage = "Please select a location"
                showAlert = true
                isCreating = false
                return
            }
            centerCoordinate = selectedLocation
        }
        
        let request = GeofenceCreateRequest(
            group_code: groupCode,
            creator_username: username,
            center_latitude: centerCoordinate.latitude,
            center_longitude: centerCoordinate.longitude,
            radius_meters: radiusMeters,
            geofence_name: geofenceName,
            follow_creator: followCreator
        )
        
        Task {
            do {
                let response = try await locationService.createGeofence(request: request)
                DispatchQueue.main.async {
                    isCreating = false
                    if response.success {
                        dismiss()
                    } else {
                        alertMessage = response.message ?? "Failed to create geofence"
                        showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isCreating = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// Helper extension for map calculations
extension MKCoordinateRegion {
    var rect: MKMapRect {
        let topLeft = CLLocationCoordinate2D(
            latitude: center.latitude + span.latitudeDelta / 2,
            longitude: center.longitude - span.longitudeDelta / 2
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: center.latitude - span.latitudeDelta / 2,
            longitude: center.longitude + span.longitudeDelta / 2
        )
        
        let topLeftMapPoint = MKMapPoint(topLeft)
        let bottomRightMapPoint = MKMapPoint(bottomRight)
        
        return MKMapRect(
            x: topLeftMapPoint.x,
            y: topLeftMapPoint.y,
            width: bottomRightMapPoint.x - topLeftMapPoint.x,
            height: bottomRightMapPoint.y - topLeftMapPoint.y
        )
    }
}

//
//  GeofenceManagementView.swift
//  tag-along
//

import SwiftUI
import MapKit

struct GeofenceManagementView: View {
    let groupCode: String
    @AppStorage("username") private var username: String = ""
    @StateObject private var locationService = LocationService()
    
    @State private var geofence: GeofenceData?
    @State private var alerts: [GeofenceAlert] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Timer for fetching alerts
    @State private var alertsTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading geofence...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let geofence = geofence {
                    // Existing geofence view
                    existingGeofenceView(geofence)
                } else {
                    // No geofence view
                    noGeofenceView
                }
            }
            .navigationTitle("Geofence")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadGeofence()
                startFetchingAlerts()
            }
            .onDisappear {
                stopFetchingAlerts()
            }
            .sheet(isPresented: $showCreateSheet) {
                GeofenceSetupView(groupCode: groupCode)
                    .onDisappear {
                        loadGeofence() // Refresh after creating
                    }
            }
            .alert("Geofence Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var noGeofenceView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Geofence Set")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a geofence to monitor when group members enter or leave a specific area.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Create Geofence") {
                showCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func existingGeofenceView(_ geofence: GeofenceData) -> some View {
        VStack {
            // Geofence info card
            VStack(alignment: .leading, spacing: 12) {
                Text(geofence.geofence_name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Label("Radius: \(Int(geofence.radius_meters))m", systemImage: "circle")
                
                if geofence.follow_creator {
                    Label("Follows creator location", systemImage: "location.fill")
                        .foregroundColor(.blue)
                } else {
                    Label("Fixed location", systemImage: "mappin")
                }
                
                HStack {
                    Button("Delete Geofence") {
                        deleteGeofence()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Recent alerts
            if !alerts.isEmpty {
                VStack(alignment: .leading) {
                    Text("Recent Alerts")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(alerts.prefix(10)) { alert in
                                GeofenceAlertRow(alert: alert)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func loadGeofence() {
        Task {
            do {
                let response = try await locationService.getGeofence(groupCode: groupCode)
                DispatchQueue.main.async {
                    isLoading = false
                    geofence = response.geofence
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    geofence = nil
                }
            }
        }
    }
    
    private func deleteGeofence() {
        Task {
            do {
                try await locationService.deleteGeofence(groupCode: groupCode, creatorUsername: username)
                DispatchQueue.main.async {
                    geofence = nil
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to delete geofence: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func startFetchingAlerts() {
        fetchAlerts()
        alertsTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            fetchAlerts()
        }
    }
    
    private func stopFetchingAlerts() {
        alertsTimer?.invalidate()
        alertsTimer = nil
    }
    
    private func fetchAlerts() {
        Task {
            do {
                let response = try await locationService.getGeofenceAlerts(groupCode: groupCode)
                DispatchQueue.main.async {
                    alerts = response.alerts
                }
            } catch {
                print("Failed to fetch alerts: \(error)")
            }
        }
    }
}

struct GeofenceAlertRow: View {
    let alert: GeofenceAlert
    
    var body: some View {
        HStack {
            Image(systemName: alert.alert_type == "entered" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(alert.alert_type == "entered" ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(alert.username) \(alert.alert_type) \(alert.geofence_name)")
                    .font(.body)
                
                if let date = alert.alertDate {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
