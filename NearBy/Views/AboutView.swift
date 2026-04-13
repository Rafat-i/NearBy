//
//  AboutView.swift
//  NearBy
//
//  Created by Rafat on 2026-04-07.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image("NearByIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(radius: 4)

                    Text("NearBy")
                        .font(.title2.bold())

                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("About") {
                Text("NearBy is a map-based iOS app that helps you discover restaurants, cafés, parks, and other points of interest around you. Save your favourites for offline access and get directions with a single tap.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section("Key Features") {
                FeatureRow(icon: "map.fill",        color: .blue,   title: "Map Discovery",     description: "Explore nearby places on an interactive map")
                FeatureRow(icon: "magnifyingglass", color: .orange, title: "Search & Filter",   description: "Filter by category, distance, and rating")
                FeatureRow(icon: "heart.fill",      color: .red,    title: "Favorites",        description: "Save places and access them offline")
                FeatureRow(icon: "arrow.triangle.turn.up.right.diamond.fill", color: .green, title: "Directions", description: "Get routes directly from the app")
                FeatureRow(icon: "note.text",       color: .purple, title: "Personal Notes",   description: "Add your own notes to any place")
            }

            Section("How to Use") {
                HelpRow(step: "1", text: "Open the Map tab to see places near you.")
                HelpRow(step: "2", text: "Tap a pin on the map to preview a place.")
                HelpRow(step: "3", text: "Tap the pin callout to open full details.")
                HelpRow(step: "4", text: "Tap the heart to save a place to Favorites.")
                HelpRow(step: "5", text: "Use the Filter button to narrow results by category, distance, or rating.")
                HelpRow(step: "6", text: "Tap Get Directions to see the route from your location.")
            }

            Section("Built With") {
                TechRow(icon: "swift",          label: "SwiftUI")
                TechRow(icon: "map",            label: "MapKit")
                TechRow(icon: "cylinder.split.1x2", label: "CoreData")
                TechRow(icon: "flame",          label: "Firebase Auth & Firestore")
            }

            Section("Team") {
                TeamRow(name: "Chadi Faour")
                TeamRow(name: "Rafat")
                TeamRow(name: "Melinda")
            }

        }
        .navigationTitle("About & Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}


private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct HelpRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct TechRow: View {
    let icon: String
    let label: String

    var body: some View {
        Label(label, systemImage: icon)
            .font(.subheadline)
    }
}

private struct TeamRow: View {
    let name: String

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.secondary)
            Text(name)
            Spacer()
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
