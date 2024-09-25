import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
    var body: some View {
        VStack {
            if let coordinate = locationManager.lastKnownLocation {
                Map(coordinateRegion: $region)
                            .frame(width: 400, height: 300)
                            .onAppear {
                                    if let coordinate = locationManager.lastKnownLocation {region.center = coordinate}
                                        }
            } else {
                Text("Unknown Location")
            }
            
            
            Button("Get location") {
                locationManager.checkLocationAuthorization()
                if let coordinate = locationManager.lastKnownLocation {
                    region.center = coordinate
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
