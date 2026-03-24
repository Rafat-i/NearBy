//
//  SettingsView.swift
//  NearBy
//
//  Created by Rafat on 2026-03-09.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = UserSettingsStore.shared

    @State private var radius: Double = 9000
    @State private var mapStyle: String = "standard"
    @State private var units: String = "metric"

    private let radiusRange: ClosedRange<Double> = 500...30000

    var body: some View {
        Form {
            Section("Map Preferences") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Default radius")
                        Spacer()
                        Text(radiusLabel(radius))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $radius, in: radiusRange, step: 500)
                }

                Picker("Map style", selection: $mapStyle) {
                    Text("Standard").tag("standard")
                    Text("Hybrid").tag("hybrid")
                    Text("Imagery").tag("imagery")
                }
            }

            Section("Units") {
                Picker("Distance units", selection: $units) {
                    Text("Metric (km/m)").tag("metric")
                    Text("Imperial (mi/ft)").tag("imperial")
                }
            }

            Section {
                Button("Save Settings") {
                    settings.save(defaultRadius: radius, mapStyle: mapStyle, units: units)
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settings.loadForCurrentUser()
            radius = settings.defaultRadius
            mapStyle = settings.mapStyle
            units = settings.units
        }
    }

    private func radiusLabel(_ meters: Double) -> String {
        if units == "imperial" {
            let miles = meters / 1609.344
            return String(format: "%.1f mi", miles)
        } else if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return "\(Int(meters)) m"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

