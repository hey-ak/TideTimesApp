import Foundation
import CoreLocation

class TideDataManager: ObservableObject {
    @Published var tideData: TideData?
    
    enum TideError: Error {
        case invalidLocation
        case dataGenerationFailed
    }
    
    func fetchTideData(for location: Location) {
        guard location.coordinate.latitude >= -90 && location.coordinate.latitude <= 90 &&
              location.coordinate.longitude >= -180 && location.coordinate.longitude <= 180 else {
            print("Invalid coordinates")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        var heights: [TideHeight] = []
        var extremes: [TideExtreme] = []
        
        let latitudeEffect = sin(location.coordinate.latitude * .pi / 180)
        let longitudeEffect = cos(location.coordinate.longitude * .pi / 180)
        
        let baseAmplitude = 1.5 + latitudeEffect * 0.5
        
        let phaseShift = longitudeEffect * 2 * .pi
        
        for halfHour in 0..<48 {
            let time = calendar.date(byAdding: .minute, value: halfHour * 30, to: now)!
            
            let progress = Double(halfHour) / 48.0
            let height = 2.0 + sin(progress * 4 * .pi + phaseShift) * baseAmplitude
            
            heights.append(TideHeight(time: time, height: height))
            
            if halfHour % 12 == 0 {
                let type: ExtremeType = halfHour % 24 == 0 ? .high : .low
                extremes.append(TideExtreme(time: time, height: height, type: type))
            }
        }
        
        tideData = TideData(heights: heights, extremes: extremes)
    }
}

struct TideData: Codable {
    let heights: [TideHeight]
    let extremes: [TideExtreme]
}

struct TideHeight: Codable {
    let time: Date
    let height: Double
}

struct TideExtreme: Codable {
    let time: Date
    let height: Double
    let type: ExtremeType
}

enum ExtremeType: String, Codable {
    case high
    case low
} 