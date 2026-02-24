//
//  CategoriesView.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-21.
//

import SwiftUI

struct CategoriesView: View {
    
    let categories = Category.defaultCategories
    var body: some View {
        HStack{
            Text("Filter")
                .font(.title)
                .fontWeight(Font.Weight.bold)
            Spacer()
        }.padding(.horizontal)
        
        ScrollView{
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20){
                ForEach(categories) { category in
                    VStack(alignment: .leading){
                        CategoryCard(category:category)
                    }
                }
            }.padding()
        }
    }
}

struct CategoryCard: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.iconName ?? "questionmark")
                .font(.system(size: 30))
                .foregroundStyle(.white.opacity(1))
            
            Text(category.name)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color(category.colorHex!))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    CategoriesView()
}
