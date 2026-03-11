//
//  RecordView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct RecordView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("记录")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("历史饮食")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    RecordView()
}