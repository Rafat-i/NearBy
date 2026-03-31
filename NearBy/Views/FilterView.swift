//
//  FilterView.swift
//  NearBy
//
//  Created by Rafat on 2026-03-30.
//


import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategory: Category?
    @Binding var selectedDistance: Double?
    @Binding var minimumRating: Double

    private let distanceOptions: [(label: String, value: Double)] = [
        ("500 m",  500),
        ("1 km",   1_000),
        ("5 km",   5_000),
        ("10 km",  10_000)
    ]

    private let ratingOptions: [Double] = [0, 2, 3, 4, 4.5]

    var activeFilterCount: Int {
        (selectedCategory != nil ? 1 : 0) +
        (selectedDistance != nil ? 1 : 0) +
        (minimumRating > 0 ? 1 : 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            categoryChip(nil)
                            ForEach(Category.defaultCategories) { category in
                                categoryChip(category)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section("Maximum Distance") {
                    HStack(spacing: 10) {
                        distanceChip(nil, label: "Any")
                        ForEach(distanceOptions, id: \.value) { option in
                            distanceChip(option.value, label: option.label)
                        }
                    }
                }

                Section("Minimum Rating") {
                    HStack(spacing: 10) {
                        ratingChip(0, label: "Any")
                        ForEach(ratingOptions.dropFirst(), id: \.self) { rating in
                            ratingChip(rating, label: "\(formatRating(rating))★")
                        }
                    }
                }

                if activeFilterCount > 0 {
                    Section {
                        Button(role: .destructive) {
                            selectedCategory = nil
                            selectedDistance = nil
                            minimumRating    = 0
                        } label: {
                            HStack {
                                Spacer()
                                Label("Reset All Filters", systemImage: "xmark.circle")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }


    @ViewBuilder
    private func categoryChip(_ category: Category?) -> some View {
        let isSelected = selectedCategory?.id == category?.id
        let label      = category?.name ?? "All"
        let icon       = category?.iconName ?? "square.grid.2x2"
        let color      = category.map { Color($0.colorHex ?? "gray") } ?? Color.gray

        Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(label).font(.caption).fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .foregroundColor(isSelected ? .white : color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func distanceChip(_ value: Double?, label: String) -> some View {
        let isSelected = selectedDistance == value
        Button {
            selectedDistance = value
        } label: {
            Text(label)
                .font(.caption).fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .foregroundColor(isSelected ? .white : .blue)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func ratingChip(_ value: Double, label: String) -> some View {
        let isSelected = minimumRating == value
        Button {
            minimumRating = value
        } label: {
            Text(label)
                .font(.caption).fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color.orange.opacity(0.1))
                .foregroundColor(isSelected ? .white : .orange)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func formatRating(_ rating: Double) -> String {
        rating == Double(Int(rating)) ? "\(Int(rating))" : String(format: "%.1f", rating)
    }
}

#Preview {
    FilterView(
        selectedCategory: .constant(nil),
        selectedDistance: .constant(nil),
        minimumRating:    .constant(0)
    )
}
