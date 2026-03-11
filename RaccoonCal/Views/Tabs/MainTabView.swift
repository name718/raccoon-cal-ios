//
//  MainTabView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
            
            RecordView()
                .tabItem {
                    Image(systemName: "list.clipboard.fill")
                    Text("记录")
                }
            
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("拍照")
                }
            
            PetView()
                .tabItem {
                    Image(systemName: "pawprint.fill")
                    Text("浣熊")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
        }
        .accentColor(AppTheme.primary) // Tab选中时的颜色
    }
}

#Preview {
    MainTabView()
}