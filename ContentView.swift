//
//  ContentView.swift
//  TideTimes
//
//  Created by Akshay Jha on 20/12/24.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var tideDataManager = TideDataManager()
    @AppStorage("savedLocation") private var savedLocation: String?
    @State private var showingLocationSearch = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let location = locationManager.selectedLocation {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                Text(location.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(formatCoordinates(location.coordinate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    if let tideData = tideDataManager.tideData {
                        VStack(spacing: 20) {
                            TideGraphView(tideData: tideData)
                                .frame(height: 300)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Next 24 Hours")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 16) {
                                    TideExtremeCard(
                                        title: "High Tides",
                                        icon: "arrow.up.circle.fill",
                                        color: .red,
                                        extremes: tideData.extremes.filter { $0.type == .high }
                                    )
                                    
                                    TideExtremeCard(
                                        title: "Low Tides",
                                        icon: "arrow.down.circle.fill",
                                        color: .blue,
                                        extremes: tideData.extremes.filter { $0.type == .low }
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "water.waves")
                                .font(.system(size: 64))
                                .foregroundColor(.accentColor)
                                .padding(.top, 60)
                            
                            Text("Select a Location")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Choose a coastal location to view tide information")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(height: 300)
                    }
                }
            }
            .navigationTitle("Tide Times")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingLocationSearch = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.circle.fill")
                                .font(.title2)
                            Text(locationManager.selectedLocation == nil ? "Select Location" : "Change")
                                .font(.body)
                        }
                        .frame(height: 44)
                    }
                }
            }
            .sheet(isPresented: $showingLocationSearch) {
                NavigationView {
                    LocationSearchView(
                        selectedLocation: $locationManager.selectedLocation,
                        isPresented: $showingLocationSearch
                    )
                    .environmentObject(locationManager)
                }
            }
            .onChange(of: locationManager.selectedLocation) { location in
                if let location = location {
                    tideDataManager.fetchTideData(for: location)
                    savedLocation = location.id
                }
            }
            .onAppear {
                if let saved = savedLocation {
                    locationManager.restoreLocation(id: saved)
                }
            }
        }
    }
    
    private func formatCoordinates(_ coordinate: CLLocationCoordinate2D) -> String {
        CoordinateFormatter.format(coordinate)
    }
}

struct TideExtremeCard: View {
    let title: String
    let icon: String
    let color: Color
    let extremes: [TideExtreme]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            ForEach(extremes, id: \.time) { extreme in
                HStack {
                    Text(formatTime(extreme.time))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(String(format: "%.1fm", extreme.height))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(color)
                }
                .padding(.horizontal)
            }
        }
        .padding()
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

#Preview {
    ContentView()
}
