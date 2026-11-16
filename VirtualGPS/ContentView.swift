import SwiftUI
import MapKit
import CoreLocation

struct SavedPlace: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
}

@MainActor
struct ContentView: View {
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @State private var selectedCoordinate = CLLocationCoordinate2D(
        latitude: 28.6139, longitude: 77.2090
    )
    @State private var latitudeText = "28.613900"
    @State private var longitudeText = "77.209000"
    @State private var searchText = ""
    @State private var placeName = "New Delhi"
    @State private var status = "Select a point on the map or search for a place."
    @State private var isSimulating = false
    @State private var savedPlaces: [SavedPlace] = []
    @State private var showingSaved = false

    private let savedKey = "VirtualGPS.savedPlaces"

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        Annotation("Selected location", coordinate: selectedCoordinate) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 34))
                                .foregroundStyle(.red)
                        }
                    }
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                        MapUserLocationButton()
                    }
                    .onTapGesture { screenPoint in
                        if let coordinate = proxy.convert(screenPoint, from: .local) {
                            setSelection(coordinate, name: "Dropped pin")
                        }
                    }
                }
                .frame(minHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 8) {
                    TextField("City, address or place", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit { searchPlace() }
                    Button("Search", action: searchPlace)
                        .buttonStyle(.borderedProminent)
                }

                HStack {
                    coordinateField("Latitude", text: $latitudeText)
                    coordinateField("Longitude", text: $longitudeText)
                }

                HStack(spacing: 10) {
                    Button("Set location") { applyCoordinates() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    Button(isSimulating ? "Stop" : "Simulate in app") {
                        isSimulating.toggle()
                        status = isSimulating
                            ? "Simulation active inside Virtual GPS only."
                            : "Simulation stopped."
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                HStack {
                    Button {
                        saveCurrentPlace()
                    } label: {
                        Label("Save place", systemImage: "bookmark")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showingSaved = true
                    } label: {
                        Label("Saved places", systemImage: "list.bullet")
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(placeName).font(.headline)
                    Text(String(format: "%.6f, %.6f",
                                selectedCoordinate.latitude,
                                selectedCoordinate.longitude))
                        .font(.system(.caption, design: .monospaced))
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("This app does not change the GPS location seen by other apps.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("Virtual GPS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: selectedCoordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.08,
                                                       longitudeDelta: 0.08)
                            )
                        )
                    } label: {
                        Image(systemName: "scope")
                    }
                    .accessibilityLabel("Center map on selected location")
                }
            }
            .sheet(isPresented: $showingSaved) {
                savedPlacesSheet
            }
            .onAppear(perform: loadSavedPlaces)
        }
    }

    private func coordinateField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: text)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var savedPlacesSheet: some View {
        NavigationStack {
            List {
                ForEach(savedPlaces) { place in
                    Button {
                        let coordinate = CLLocationCoordinate2D(
                            latitude: place.latitude, longitude: place.longitude
                        )
                        setSelection(coordinate, name: place.name)
                        showingSaved = false
                    } label: {
                        VStack(alignment: .leading) {
                            Text(place.name).foregroundStyle(.primary)
                            Text(String(format: "%.6f, %.6f",
                                        place.latitude, place.longitude))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    savedPlaces.remove(atOffsets: offsets)
                    persistSavedPlaces()
                }
            }
            .navigationTitle("Saved places")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingSaved = false }
                }
            }
        }
    }

    private func setSelection(_ coordinate: CLLocationCoordinate2D, name: String) {
        selectedCoordinate = coordinate
        latitudeText = String(format: "%.6f", coordinate.latitude)
        longitudeText = String(format: "%.6f", coordinate.longitude)
        placeName = name
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
        status = "Location selected. Tap Set location to confirm."
    }

    private func applyCoordinates() {
        guard let lat = Double(latitudeText),
              let lon = Double(longitudeText),
              (-90.0...90.0).contains(lat),
              (-180.0...180.0).contains(lon) else {
            status = "Enter a valid latitude (-90 to 90) and longitude (-180 to 180)."
            return
        }
        setSelection(
            CLLocationCoordinate2D(latitude: lat, longitude: lon),
            name: "Custom coordinates"
        )
        status = "Location set inside Virtual GPS."
    }

    private func searchPlace() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        let geocoder = CLGeocoder()
        status = "Searching…"
        geocoder.geocodeAddressString(query) { placemarks, error in
            Task { @MainActor in
                if let coordinate = placemarks?.first?.location?.coordinate {
                    let name = placemarks?.first?.name ?? query
                    setSelection(coordinate, name: name)
                    status = "Place found. Tap Set location to confirm."
                } else {
                    status = error?.localizedDescription ?? "No matching place found."
                }
            }
        }
    }

    private func saveCurrentPlace() {
        let item = SavedPlace(
            name: placeName,
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude
        )
        if !savedPlaces.contains(where: {
            $0.latitude == item.latitude && $0.longitude == item.longitude
        }) {
            savedPlaces.append(item)
            persistSavedPlaces()
        }
        status = "Saved to favourites."
    }

    private func loadSavedPlaces() {
        guard let data = UserDefaults.standard.data(forKey: savedKey),
              let places = try? JSONDecoder().decode([SavedPlace].self, from: data)
        else { return }
        savedPlaces = places
    }

    private func persistSavedPlaces() {
        guard let data = try? JSONEncoder().encode(savedPlaces) else { return }
        UserDefaults.standard.set(data, forKey: savedKey)
    }
}

#Preview {
    ContentView()
}
