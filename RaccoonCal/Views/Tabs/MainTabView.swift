//
//  MainTabView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)

            RecordView()
                .tabItem {
                    Image(systemName: "list.clipboard.fill")
                    Text("记录")
                }
                .tag(1)

            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("拍照")
                }
                .tag(2)

            PetView()
                .tabItem {
                    Image(systemName: "pawprint.fill")
                    Text("浣熊")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(4)
        }
        .accentColor(AppTheme.primary)
        .environmentObject(appState)
    }
}

#Preview {
    MainTabView()
}
