import Foundation
import CoreLocation
import SwiftUI
import MapKit

final class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    @Published var lastKnownLocation: CLLocationCoordinate2D?
    var manager = CLLocationManager()
    
    
    func checkLocationAuthorization() -> String {
        
        manager.delegate = self
        manager.startUpdatingLocation()
        
        switch manager.authorizationStatus {
        case .notDetermined:
            askLocationPermission()
            return("Not determined")
            
        case .restricted://The user cannot change this app’s status, possibly due to active restrictions such as parental controls being in place.
            return("Location restricted")
            
        case .denied://The user dennied your app to get location or disabled the services location or the phone is in airplane mode
            return("Location denied")
            
        case .authorizedAlways://This authorization allows you to use all location services and receive location events whether or not your app is in use.
            lastKnownLocation = manager.location?.coordinate
            return("AuthorizedAlways")
            
        case .authorizedWhenInUse://This authorization allows you to use all location services and receive location events only when your app is in use
            lastKnownLocation = manager.location?.coordinate
            return("Authorized whenInUse")
            
        @unknown default:
            return("Unknown error")
        }
    }
    
    func askLocationPermission()
    {
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {//Trigged every time authorization status changes
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.first?.coordinate
    }
    
    func savePoints(mapPoints: [MKMapItem], pointsColors: [Color]) {
        for (index, point) in mapPoints.enumerated() {
            print(index)
            if let name = point.name {
                do {
                    let latString = String(format: "%.6f", point.placemark.coordinate.latitude)
                    let longString = String(format: "%.6f", point.placemark.coordinate.longitude)
                    let encodedName = try JSONEncoder().encode(name)
                    let encodedLat = try JSONEncoder().encode(latString)
                    let encodedLong = try JSONEncoder().encode(longString)
                    
                    let components = UIColor(pointsColors[index]).cgColor.components ?? [0, 0, 0, 0]
                    let r = Int(components[0] * 255.0)
                    let g = Int(components[1] * 255.0)
                    let b = Int(components[2] * 255.0)
                    let colorString = String(format: "#%02X%02X%02X", r, g, b)
                    
                    let encodedColor = try JSONEncoder().encode(colorString)
                    UserDefaults.standard.set(encodedName, forKey: "name\(index)")
                    UserDefaults.standard.set(encodedLat, forKey: "lat\(index)")
                    UserDefaults.standard.set(encodedLong, forKey: "long\(index)")
                    UserDefaults.standard.set(encodedColor, forKey: "color\(index)")
                }
                catch {
                    print("error happened")
                }
            }
        }
        let encodedLength = try? JSONEncoder().encode(mapPoints.count)
        UserDefaults.standard.set(encodedLength, forKey: "length")
    }

    func loadPoints() -> (mapPoints:[MKMapItem]?,pointsColors:[Color]?) {
        var mapPoints: [MKMapItem] = [];
        var pointsColors: [Color] = [];
        if let lengthData = UserDefaults.standard.data(forKey: "length") {
            do {
                let decodedLength = try JSONDecoder().decode(Int.self, from: lengthData)
                for (index) in 0..<decodedLength {
                    print(index)
                    if let nameData = UserDefaults.standard.data(forKey: "name\(index)"),
                    let latData = UserDefaults.standard.data(forKey: "lat\(index)"),
                    let longData = UserDefaults.standard.data(forKey: "long\(index)"),
                    let colorData = UserDefaults.standard.data(forKey: "color\(index)")
                    {
                        let decodedName = try JSONDecoder().decode(String.self, from: nameData)
                        let decodedLat = try JSONDecoder().decode(String.self, from: latData)
                        let decodedLong = try JSONDecoder().decode(String.self, from: longData)
                        let decodedColor = try JSONDecoder().decode(String.self, from: colorData)
                        
                        var hexSanitized = decodedColor.trimmingCharacters(in: .whitespacesAndNewlines)
                        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
                        var rgb: UInt64 = 0
                        Scanner(string: hexSanitized).scanHexInt64(&rgb)
                        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
                        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
                        let b = CGFloat(rgb & 0xFF) / 255.0
                        let newColor = Color.init(red: r, green: g, blue: b)
                        
                        if let doubleLong = Double(decodedLong),
                           let doubleLat = Double(decodedLat) {
                            let mapItem = MKMapItem(
                                placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: doubleLat,
                                    longitude: doubleLong))
                            )
                            mapItem.name = decodedName
                            mapPoints.append(mapItem)
                            pointsColors.append(newColor)
                        }
                    }
                }
                return (mapPoints, pointsColors)
            } catch {
                print("Failed to decode length: \(error)")
            }
        }
        return (nil, nil)
    }
}
