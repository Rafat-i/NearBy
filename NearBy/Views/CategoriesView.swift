//
//  CategoriesView.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-21.
//

import SwiftUI
import Combine

struct CategoriesView: View {
    @ObservedObject var filter: MapFilter
    let categories = Category.defaultCategories

    var body: some View {
        
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(categories) { category in
                        NavigationLink(destination: CategoryPlacesListView(category: category)) {
                            CategoryCard(category: category)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
        }
    }


struct CategoryCard: View {
    let category: Category

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.iconName ?? "questionmark")
                .font(.system(size: 30))
                .foregroundStyle(Color(category.colorHex ?? "gray"))

            Text(category.name)
                .font(.headline)
                .foregroundColor(Color(category.colorHex ?? "gray"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color(category.colorHex ?? "gray").opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(category.colorHex ?? "gray").opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    CategoriesView(filter: MapFilter())
}
