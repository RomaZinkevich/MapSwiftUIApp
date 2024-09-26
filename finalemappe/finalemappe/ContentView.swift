import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State private var showAlert = false;
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Map(coordinateRegion: $region)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        updateLocation()
                    }
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
                region.center = coordinate
        }
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
