//
//  PetView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct PetView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("浣熊")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("养成、装扮")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("浣熊")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    PetView()
}