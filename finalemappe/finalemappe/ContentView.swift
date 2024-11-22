import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State var position : MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384),
        latitudinalMeters: 100000,
        longitudinalMeters: 45995
    ))
    @State private var mapPoints: [MKMapItem] = []
    @State private var pointsColors: [Color] = []
    @State private var showAlert = false;
    @State private var showAddAlert = false;
    @State private var showInputModal = false
    @State private var showPinsList = false
    @State private var markerName: String = ""
    @State private var selectedColor: Color = .red
    @State private var tappedCoordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    @State private var updateLocationImg = "location"
    private var latOffset = -0.068;
    private var longOffset = 0.0;
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MapReader { proxy in
                    Map(position: $position) {
                        ForEach(Array(mapPoints.enumerated()), id: \.element) { index, point in
                            if let name = point.name {
                                Marker(name, coordinate: point.placemark.coordinate).tint(pointsColors[index])
                            }
                        }
                        UserAnnotation()
                    }
                        .onMapCameraChange { context in
                            position = MapCameraPosition.region(
                                        MKCoordinateRegion(
                                            center: context.region.center,
                                            span: context.region.span
                                        )
                                    )
                            if let knownCoords = locationManager.lastKnownLocation {
                                if (String(format: "%.6f", context.region.center.latitude) == String(format: "%.6f", knownCoords.latitude)) {
                                    updateLocationImg="location.fill"
                                }
                                else {
                                    updateLocationImg="location"
                                }
                            }
                            
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            let result = locationManager.loadPoints()
                            if let mappins = result.0,
                               let colors = result.1
                            {
                                mapPoints = mappins
                                pointsColors = colors
                            }
                            updateLocation()
                        }
                        .onTapGesture { position in
                            handleTapGesture(location: position, proxy: proxy)
                    }
                }
                HStack{
                    Spacer()
                    VStack {
                        Button(action: updateLocation) {
                            Image(systemName: updateLocationImg)
                        }
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(10)
                        .padding()
                        Spacer()
                        Button(action: showPins) {
                            Image(systemName: "mappin")
                        }
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(10)
                        .padding()
                    }
                }
                
                
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                let answer = locationManager.checkLocationAuthorization()
                if answer == "Location denied" {
                    showAlert=true;
                }
            }
            .sheet(isPresented: $showPinsList){
                VStack {
                    Text("Marked Locations")
                    .font(.title)
                    .padding()
                    List {
                        ForEach(Array(mapPoints.enumerated()), id: \.element) { index, point in
                            if let name = point.name {
                                let latString = String(format: "%.6f", point.placemark.coordinate.latitude)
                                let longString = String(format: "%.6f", point.placemark.coordinate.longitude)
                                let text = "\(name)\nLat: \(latString)\nLong: \(longString)"
                                VStack {
                                    Text(text)
                                    Button("Show location") {
                                        updateMap(coordinate: point.placemark.coordinate, latMeters: 1000.0)
                                        showPinsList=false;
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                                
                            }
                            else {
                                Text("Empty")
                            }
                        }
                        if (mapPoints.count >= 1) {
                            Button("Reset saved locations") {
                                locationManager.removePoints()
                                mapPoints=[]
                                pointsColors=[]
                                showPinsList=false;
                            }
                            .foregroundColor(.red)
                        }
                    }
                    if (mapPoints.count < 1) {
                        Text("None yet")
                    }
                }
            }
            .alert("Add Marker?", isPresented: $showAddAlert) {
                Button("Add") {
                    showInputModal = true // Show modal for name and color
                }
                    Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showInputModal) {
                VStack {
                    Text("Enter Marker Name")
                    TextField("Marker Name", text: $markerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    ColorPicker("Select Color", selection: $selectedColor)
                        .padding()
                    Button("Save") {
                        addMapItem(adjustedCoordinate: tappedCoordinate)
                        showInputModal = false
                    }
                    .padding()
                }
                .padding()
            }
            .alert("Location Access Denied", isPresented: $showAlert) {
                Button("Open settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message : {
                Text("Please allow location access in settings to use this app.")
            }
        }
    }
    
    func showPins() {
        showPinsList=true
    }
    
    func updateLocation(){
        let answer = locationManager.checkLocationAuthorization()
        if answer == "Location denied" {
            showAlert=true;
        } else if let coordinate = locationManager.lastKnownLocation {
            updateMap(coordinate: coordinate, latMeters: 10000.0)
        }
    }
    
    func updateMap(coordinate: CLLocationCoordinate2D, latMeters: CGFloat){
        let aspectRatio: CGFloat = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        let latDeltaMeters = latMeters;
        let longDeltaMeters = latDeltaMeters * aspectRatio
        print(coordinate)
        position = .region(MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: latDeltaMeters,
            longitudinalMeters: longDeltaMeters
        ))
    }
    
    func handleTapGesture(location: CGPoint, proxy: MapProxy){
        if let coordinate =
            proxy.convert(location, from: .local){
            if let span = position.region?.span {
                let latDelta = span.latitudeDelta
                let longDelta = span.longitudeDelta
                let adjustedCoordinate = CLLocationCoordinate2D(
                    latitude: coordinate.latitude+latOffset*latDelta,
                    longitude: coordinate.longitude+longOffset*longDelta
                )
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: adjustedCoordinate.latitude, longitude: adjustedCoordinate.longitude)
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    if let error = error {
                        print("Reverse geocoding error: \(error.localizedDescription)")
                        markerName = ""
                    } else if let placemark = placemarks?.first {
                        markerName = placemark.name ?? "Unknown Location"
                    }
                }
                tappedCoordinate = adjustedCoordinate
                showAddAlert = true
            }
            else {
                print("Something went wrong")
            }
        }
    }
    
    func addMapItem(adjustedCoordinate: CLLocationCoordinate2D){
        let mapItem = MKMapItem(
            placemark: MKPlacemark(coordinate: adjustedCoordinate)
        )
        mapItem.name = markerName
        pointsColors.append(selectedColor)
        mapPoints.append(mapItem)
        locationManager.savePoints(mapPoints: mapPoints, pointsColors: pointsColors)
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
