import CoreLocation

struct CoordinateFormatter {
    static func format(_ coordinate: CLLocationCoordinate2D) -> String {
        let latitude = abs(coordinate.latitude)
        let longitude = abs(coordinate.longitude)
        let latDirection = coordinate.latitude >= 0 ? "N" : "S"
        let lonDirection = coordinate.longitude >= 0 ? "E" : "W"
        
        return String(
            format: "%.1f°%@ %.1f°%@",
            latitude,
            latDirection,
            longitude,
            lonDirection
        )
    }
} 