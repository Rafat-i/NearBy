//
//  SearchBarView.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-06.
//

import SwiftUI

struct SearchBarView: View {
    
    @State private var textInput: String = ""
    
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                TextField("Search", text:$textInput)
            }.padding()
                .background(RoundedRectangle(cornerRadius:35).fill(.white))
                .shadow(radius: 5, y: 5)
        }.padding(.horizontal)
    }
}

#Preview {
    SearchBarView()
}
