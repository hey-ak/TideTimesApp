import Foundation
import CoreLocation

class LocationManager: ObservableObject {
    @Published var selectedLocation: Location?
    @Published var searchResults: [Location] = []
    
    private let geocoder = CLGeocoder()
    private var savedLocations: [String: Location] = [:]
    
    init() {
        searchResults = [
            Location(
                id: "sydney",
                name: "Sydney, Australia",
                coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
            ),
            Location(
                id: "miami",
                name: "Miami Beach, Florida",
                coordinate: CLLocationCoordinate2D(latitude: 25.7907, longitude: -80.1300)
            ),
            Location(
                id: "honolulu",
                name: "Honolulu, Hawaii",
                coordinate: CLLocationCoordinate2D(latitude: 21.3069, longitude: -157.8583)
            ),
            Location(
                id: "capetown",
                name: "Cape Town, South Africa",
                coordinate: CLLocationCoordinate2D(latitude: -33.9249, longitude: 18.4241)
            ),
            Location(
                id: "dubai",
                name: "Dubai Marina, UAE",
                coordinate: CLLocationCoordinate2D(latitude: 25.0817, longitude: 55.1361)
            ),
            Location(
                id: "rio",
                name: "Rio de Janeiro, Brazil",
                coordinate: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729)
            ),
            Location(
                id: "venice",
                name: "Venice, Italy",
                coordinate: CLLocationCoordinate2D(latitude: 45.4408, longitude: 12.3155)
            ),
            Location(
                id: "maldives",
                name: "Male, Maldives",
                coordinate: CLLocationCoordinate2D(latitude: 4.1755, longitude: 73.5093)
            )
        ]
    }
    
    func searchLocations(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                resetToDefaultLocations()
            }
            return
        }
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            guard !placemarks.isEmpty else {
                throw LocationError.noResults
            }
            
            await MainActor.run {
                searchResults = placemarks.compactMap { placemark in
                    guard let coordinate = placemark.location?.coordinate,
                          let name = placemark.name else { return nil }
                    
                    let location = Location(
                        id: "\(coordinate.latitude),\(coordinate.longitude)",
                        name: name,
                        coordinate: coordinate
                    )
                    savedLocations[location.id] = location
                    return location
                }
            }
        } catch LocationError.noResults {
            await MainActor.run {
                searchResults = []
            }
        } catch {
            print("Geocoding error: \(error.localizedDescription)")
            await MainActor.run {
                searchResults = []
            }
        }
    }
    
    func resetToDefaultLocations() {
        searchResults = [
            Location(
                id: "sydney",
                name: "Sydney, Australia",
                coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
            ),
            Location(
                id: "miami",
                name: "Miami Beach, Florida",
                coordinate: CLLocationCoordinate2D(latitude: 25.7907, longitude: -80.1300)
            )
        ]
    }
    
    func restoreLocation(id: String) {
        if let location = savedLocations[id] {
            selectedLocation = location
        } else {
            let components = id.split(separator: ",")
            if components.count == 2,
               let lat = Double(components[0]),
               let lng = Double(components[1]) {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                Task {
                    do {
                        let placemarks = try await geocoder.reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lng))
                        if let name = placemarks.first?.name {
                            let location = Location(id: id, name: name, coordinate: coordinate)
                            await MainActor.run {
                                self.selectedLocation = location
                                self.savedLocations[id] = location
                            }
                        }
                    } catch {
                        print("Reverse geocoding error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

struct Location: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coordinate
    }
    
    init(id: String, name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        coordinate = try container.decode(CLLocationCoordinate2D.self, forKey: .coordinate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate, forKey: .coordinate)
    }
    
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

enum LocationError: Error {
    case invalidCoordinates
    case geocodingFailed
    case noResults
} 