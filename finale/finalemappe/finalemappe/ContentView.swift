import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State var position : MapCameraPosition = .automatic
    @State private var mapPoints: [MKMapItem] = []
    @State private var pointsColors: [Color] = []
    @State private var showAlert = false;
    @State private var showAddAlert = false;
    @State private var showInputModal = false
    @State private var markerName: String = ""
    @State private var selectedColor: Color = .red
    @State private var tappedCoordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    private var latOffset = -0.068;
    private var longOffset = 0.0;
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                MapReader { proxy in
                    Map(position: $position) {
                        ForEach(Array(mapPoints.enumerated()), id: \.element) { index, point in
                            if let name = point.name {
                                Marker(name, coordinate: point.placemark.coordinate).tint(pointsColors[index])
                            }
                            
                        }
                    }
                        .onMapCameraChange { context in
                            position = MapCameraPosition.region(
                                        MKCoordinateRegion(
                                            center: context.region.center,
                                            span: context.region.span
                                        )
                                    )
                            
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            updateLocation()
                        }
                        .onTapGesture { position in
                            handleTapGesture(location: position, proxy: proxy)
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
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                updateLocation()
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
    
    func updateLocation(){
        let answer = locationManager.checkLocationAuthorization()
        if answer == "Location denied" {
            showAlert=true;
        } else if let coordinate = locationManager.lastKnownLocation {
            let aspectRatio: CGFloat = UIScreen.main.bounds.width / UIScreen.main.bounds.height
            let latDeltaMeters = 1000.0;
            let longDeltaMeters = latDeltaMeters * aspectRatio
            position = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: latDeltaMeters,
                longitudinalMeters: longDeltaMeters
            ))
        }
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
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
