//
//  MapView.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-06.
//

import SwiftUI
import MapKit


struct MapView: View {
    //Will become a state variable to update realtime as the user moves
    let cameraPosition: MapCameraPosition = .automatic

    //Temp places
    struct Places: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
        let systemImage: String
        let color: Color
    }
    let places : [Places] = [
        .init(name: "LaSalle College", coordinate: .laSalleCollege, systemImage: "graduationcap.fill", color: .red),
        .init(name: "McGill University", coordinate: .mcGill, systemImage: "graduationcap.fill", color: .red),
        .init(name: "Mount Royal", coordinate: .mountRoyal, systemImage: "mountain.2.fill", color: .green),
        .init(name: "Bell Centre", coordinate: .bellCentre, systemImage: "figure.hockey", color: .blue)
    ]
    
    var body: some View {
        ZStack{
            Map(initialPosition: cameraPosition){
                
                ForEach(places) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            Image(systemName: place.systemImage)
                                .resizable()
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .padding(8)
                                .background(place.color.gradient, in: .circle)
                        }
                    }
            }
            VStack{
                SearchBarView()
                HStack{
                    Spacer()
                    //Filter btn in progress - temp dst: ProfileView
                    HStack{
                        NavigationLink(
                            destination: ProfileView()
                        ) {
                            Image(systemName: "slider.vertical.3")
                                .font(.system(size: 30, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(.blue))
                        }
                    }

                }.padding(.horizontal)
                Spacer()
            }
        }
    }
}

#Preview {
    MapView()
}


//temp cordinates
extension CLLocationCoordinate2D{
    static let laSalleCollege = CLLocationCoordinate2D(latitude: 45.4915, longitude: -73.5815)
    static let mcGill = CLLocationCoordinate2D(latitude: 45.5048, longitude: -73.5772)
    static let mountRoyal = CLLocationCoordinate2D(latitude: 45.5071, longitude: -73.5875)
    static let bellCentre = CLLocationCoordinate2D(latitude: 45.4961, longitude: -73.5695)
    static let museumOfFineArts = CLLocationCoordinate2D(latitude: 45.4987, longitude: -73.5794)
    
}
