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
    let cameraPosition: MapCameraPosition = .region(.init(center: .init(latitude: 37.3346, longitude: -122.0090), latitudinalMeters: 1300, longitudinalMeters: 1300))
    
    
    
    var body: some View {
        ZStack{
            Map(initialPosition: cameraPosition){
                Marker("AppleHQ", systemImage: "laptopcomputer", coordinate: .appleHQ)
                Marker("AppleHQ", systemImage: "laptopcomputer", coordinate: .appleHQ)
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


//temp markers data
extension CLLocationCoordinate2D{
    
    static let appleHQ = CLLocationCoordinate2D(latitude: 37.3346, longitude: -122.0097)
}
