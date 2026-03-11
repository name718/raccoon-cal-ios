//
//  CameraView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct CameraView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("拍照")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("相机入口（突出，中间）")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("拍照")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    CameraView()
}