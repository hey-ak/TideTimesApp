import SwiftUI
import CoreLocation

struct LocationSearchView: View {
    @State private var searchText = ""
    @StateObject private var searchDebouncer = Debouncer(delay: 0.5)
    @Binding var selectedLocation: Location?
    @Binding var isPresented: Bool
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 17))
                
                TextField("City, region, or landmark", text: $searchText)
                    .font(.system(size: 17))
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        Task {
                            await locationManager.searchLocations(query: searchText)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        locationManager.searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 17))
                    }
                    .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
                .padding(.top, 8)
            
            Group {
                if locationManager.searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.slash.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                            .padding(.top, 60)
                        
                        Text("No Locations Found")
                            .font(.headline)
                        
                        Text("Try searching with a different term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else if !locationManager.searchResults.isEmpty {
                    List {
                        ForEach(locationManager.searchResults) { location in
                            Button(action: {
                                selectedLocation = location
                                isPresented = false
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentColor.opacity(0.1))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(location.name)
                                            .font(.system(size: 17))
                                            .foregroundColor(.primary)
                                        
                                        Text(formatCoordinates(location.coordinate))
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                } else {
                    List {
                        Section(header: Text("Popular Locations")) {
                            ForEach(locationManager.searchResults) { location in
                                Button(action: {
                                    selectedLocation = location
                                    isPresented = false
                                }) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.accentColor.opacity(0.1))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.accentColor)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(location.name)
                                                .font(.system(size: 17))
                                                .foregroundColor(.primary)
                                            
                                            Text(formatCoordinates(location.coordinate))
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty {
                searchDebouncer.debounce {
                    Task {
                        do {
                            await locationManager.searchLocations(query: newValue)
                        } catch {
                            print("Search error: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                locationManager.resetToDefaultLocations()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
                .frame(width: 44, height: 44)
            }
            
            ToolbarItem(placement: .principal) {
                Text("Choose Location")
                    .font(.headline)
            }
        }
    }
    
    private func formatCoordinates(_ coordinate: CLLocationCoordinate2D) -> String {
        CoordinateFormatter.format(coordinate)
    }
} 