//
//  OnboardingView.swift
//  NearBy
//
//  Created by Rafat on 2026-03-09.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingCard(
                    title: "Welcome to NearBy",
                    subtitle: "Discover great places around you with map-based exploration.",
                    icon: "map.fill",
                    color: .blue
                )
                .tag(0)

                OnboardingCard(
                    title: "Save Favorites Offline",
                    subtitle: "Keep favorite places and personal notes synced with your account.",
                    icon: "heart.fill",
                    color: .red
                )
                .tag(1)

                VStack(spacing: 16) {
                    OnboardingCard(
                        title: "Enable Location Access",
                        subtitle: "We use your location to show nearby places and calculate routes.",
                        icon: "location.fill",
                        color: .green
                    )

                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack {
                if page < 2 {
                    Button("Skip") {
                        onFinish()
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button(page == 2 ? "Get Started" : "Next") {
                    if page < 2 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

private struct OnboardingCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.white)
                .padding(24)
                .background(color.gradient, in: Circle())

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(onFinish: {})
}

