//
//  RaccoonCalApp.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

@main
struct RaccoonCalApp: App {
    @StateObject private var userManager = UserManager.shared
    
    var body: some Scene {
        WindowGroup {
            if userManager.isLoggedIn {
                MainTabView()
            } else {
                LaunchView()
            }
        }
        .task {
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                NotificationManager.shared.scheduleDailyCheckin(hour: 20, minute: 0)
                NotificationManager.shared.scheduleTaskRefresh(hour: 9, minute: 0)
            }
        }
    }
}
