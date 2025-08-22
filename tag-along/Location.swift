//
//  Location.swift
//  tag-along
//
//  Created by Havish Komatreddy on 7/18/25.
//

import Foundation
import CoreLocation
import Combine

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation = false
    @Published var locationError: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = "Location access denied. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        locationError = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
        isUpdatingLocation = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Clear any previous errors
            locationError = nil
            // Only start if location sharing is enabled
                startLocationUpdates()
        case .denied, .restricted:
            locationError = "Location access denied"
            stopLocationUpdates()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Location Service
class LocationService: ObservableObject {
    
    func updateLocation(request: LocationUpdateRequest) async throws {
        guard let url = URL(string: "\(baseURL)/locations/update") else {
            throw LocationError.invalidURL
        }
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try JSONEncoder().encode(request)

        let (_, resp) = try await URLSession.shared.data(for: r)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw LocationError.serverError
        }
    }
    
    func getGroupLocations(groupCode: String) async throws -> GroupLocationsResponse {
        guard let url = URL(string: "\(baseURL)/groups/\(groupCode)/locations") else {
            throw LocationError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LocationError.serverError
        }
        
        return try JSONDecoder().decode(GroupLocationsResponse.self, from: data)
    }
    
    func deleteLocation(username: String, groupCode: String) async throws {
        guard let url = URL(string: "\(baseURL)/locations/\(username)/\(groupCode)") else {
            throw LocationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LocationError.serverError
        }
    }
}

// MARK: - Data Models
struct LocationUpdateRequest: Codable {
    let username: String
    let group_code: String
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    let timestamp: String?
    let is_sharing_enabled: Bool    // ← ADD THIS
}

struct UserLocationData: Codable, Identifiable, Equatable {
    var id: String { username }
    let username: String
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    let last_updated: String
    
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var lastUpdatedDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: last_updated)
    }
}

struct GroupLocationsResponse: Codable {
    let group_code: String
    let locations: [UserLocationData]
    let total_members: Int
    let active_locations: Int
}

// MARK: - Errors
enum LocationError: Error, LocalizedError {
    case invalidURL
    case serverError
    case permissionDenied
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .serverError:
            return "Server error occurred"
        case .permissionDenied:
            return "Location permission denied"
        case .locationUnavailable:
            return "Location unavailable"
        }
    }
}
// MARK: — Active Group Lookup
struct ActiveGroupResponse: Codable {
    let success: Bool
    let group_code: String?
    let message: String?       // when no active group
}

extension LocationService {
    func getActiveGroup(for username: String) async throws -> ActiveGroupResponse {
        guard let url = URL(string: "\(baseURL)/users/\(username)/active-group") else {
            throw LocationError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        // add auth header here if needed
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw LocationError.serverError
        }
        return try JSONDecoder().decode(ActiveGroupResponse.self, from: data)
    }
}
