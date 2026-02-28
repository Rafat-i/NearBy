    //
    //  CategoriesView.swift
    //  NearBy
    //
    //  Created by Ace of Heart on 2026-02-21.
    //

    import SwiftUI
    import Combine

    struct CategoriesView: View {
        @Environment(\.dismiss) private var dismiss
        @ObservedObject var filter: MapFilter
        let categories = Category.defaultCategories
        
            
        var body: some View {
            HStack{
                Text("Filter")
                    .font(.title)
                    .fontWeight(Font.Weight.bold)
                Spacer()
            }.padding(.horizontal)
            
            ScrollView{
                    Button(action:{
                        filter.selectedCategory = nil
                        dismiss()
                    }) {
                        Text("All")
                            .font(.system(size: 30))
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(.gray.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    ).padding(.bottom)
                    ForEach(categories) { category in
                        VStack(alignment: .leading){
                            Button(action: {
                                filter.selectedCategory = category
                                dismiss()
                            }) {
                                CategoryCard(category:category)
                            }
                        }.padding(.bottom)
                    }
            }.padding()
            }
        }
    

    struct CategoryCard: View {
        let category: Category
        
        var body: some View {
            VStack(spacing: 12) {
                Image(systemName: category.iconName ?? "questionmark")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(category.colorHex!))
                
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(Color(category.colorHex!))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color(category.colorHex!).opacity(0.12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(category.colorHex!).opacity(0.3), lineWidth: 1)
            )
        }
    }


#Preview {
    CategoriesView(filter: MapFilter())
}
