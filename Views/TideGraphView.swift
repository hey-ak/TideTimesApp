import SwiftUI

struct TideGraphView: View {
    let tideData: TideData
    
    private var currentHeight: Double {
        let now = Date()
        return tideData.heights
            .min(by: { abs($0.time.timeIntervalSince(now)) < abs($1.time.timeIntervalSince(now)) })?
            .height ?? 0
    }
    
    private var visibleTimeRange: (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current
        
        // Show 6 hours before and after current time
        let start = calendar.date(byAdding: .hour, value: -6, to: now) ?? now
        let end = calendar.date(byAdding: .hour, value: 6, to: now) ?? now
        
        return (start, end)
    }
    
    private var visibleHeights: [TideHeight] {
        tideData.heights.filter { height in
            height.time >= visibleTimeRange.start && height.time <= visibleTimeRange.end
        }
    }
    
    private var visibleExtremes: [TideExtreme] {
        tideData.extremes.filter { extreme in
            extreme.time >= visibleTimeRange.start && extreme.time <= visibleTimeRange.end
        }
    }
    
    private var heightRange: (min: Double, max: Double) {
        let heights = visibleHeights.map(\.height)
        let min = (heights.min() ?? 0)
        let max = (heights.max() ?? 1)
        let buffer = (max - min) * 0.1
        return (min - buffer, max + buffer)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tide Height")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("meters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            GeometryReader { geometry in
                let heightScale = geometry.size.height / (heightRange.max - heightRange.min)
                let timeWidth = geometry.size.width
                
                ZStack {
                    // Background grid
                    VStack(spacing: geometry.size.height / 6) {
                        ForEach(0...6, id: \.self) { i in
                            HStack {
                                Text(String(format: "%.1f", heightRange.max - (heightRange.max - heightRange.min) * Double(i) / 6))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 1)
                            }
                        }
                    }
                    
                    // Time markers
                    VStack {
                        Spacer()
                        HStack(spacing: timeWidth / 6) {
                            ForEach(0...6, id: \.self) { hour in
                                let date = Calendar.current.date(byAdding: .hour, value: hour - 3, to: Date()) ?? Date()
                                Text(formatTime(date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    
                    // Tide curve with gradient fill
                    Path { path in
                        let points = visibleHeights.enumerated().map { index, height in
                            CGPoint(
                                x: timeWidth * Double(index) / Double(visibleHeights.count - 1),
                                y: geometry.size.height - (height.height - heightRange.min) * heightScale
                            )
                        }
                        
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        if let firstPoint = points.first {
                            path.addLine(to: CGPoint(x: firstPoint.x, y: geometry.size.height))
                            path.addLine(to: firstPoint)
                        }
                        
                        for index in 1..<points.count {
                            let point = points[index]
                            let control1 = CGPoint(
                                x: points[index-1].x + (point.x - points[index-1].x) / 2,
                                y: points[index-1].y
                            )
                            let control2 = CGPoint(
                                x: points[index-1].x + (point.x - points[index-1].x) / 2,
                                y: point.y
                            )
                            path.addCurve(to: point, control1: control1, control2: control2)
                        }
                        
                        if let lastPoint = points.last {
                            path.addLine(to: CGPoint(x: lastPoint.x, y: geometry.size.height))
                        }
                    }
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.blue.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    
                    // Tide curve line
                    Path { path in
                        let points = visibleHeights.enumerated().map { index, height in
                            CGPoint(
                                x: timeWidth * Double(index) / Double(visibleHeights.count - 1),
                                y: geometry.size.height - (height.height - heightRange.min) * heightScale
                            )
                        }
                        
                        if let firstPoint = points.first {
                            path.move(to: firstPoint)
                        }
                        
                        for index in 1..<points.count {
                            let point = points[index]
                            let control1 = CGPoint(
                                x: points[index-1].x + (point.x - points[index-1].x) / 2,
                                y: points[index-1].y
                            )
                            let control2 = CGPoint(
                                x: points[index-1].x + (point.x - points[index-1].x) / 2,
                                y: point.y
                            )
                            path.addCurve(to: point, control1: control1, control2: control2)
                        }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    // Current time indicator
                    let currentY = geometry.size.height - (currentHeight - heightRange.min) * heightScale
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .position(x: timeWidth / 2, y: currentY)
                    
                    Text(String(format: "%.1fm", currentHeight))
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .position(x: timeWidth / 2, y: currentY - 20)
                    
                    // Extremes markers
                    ForEach(visibleExtremes, id: \.time) { extreme in
                        let progress = extreme.time.timeIntervalSince(visibleTimeRange.start) / visibleTimeRange.end.timeIntervalSince(visibleTimeRange.start)
                        let x = timeWidth * progress
                        let y = geometry.size.height - (extreme.height - heightRange.min) * heightScale
                        
                        Circle()
                            .fill(extreme.type == .high ? Color.red : Color.blue)
                            .frame(width: 8, height: 8)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .position(x: x, y: y)
                        
                        Text(formatTime(extreme.time))
                            .font(.caption2)
                            .foregroundColor(extreme.type == .high ? .red : .blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .position(x: x, y: y - 20)
                    }
                }
                .padding(.leading, 30)
                .padding(.trailing, 8)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
} 