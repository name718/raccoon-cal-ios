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
    @State private var hasRequestedNotifications = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userManager.isRestoringSession {
                    LaunchView()
                } else if userManager.isLoggedIn {
                    MainTabView()
                } else {
                    LaunchView()
                }
            }
            .onAppear {
                guard !hasRequestedNotifications else { return }
                hasRequestedNotifications = true

                Task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted {
                        NotificationManager.shared.scheduleDailyCheckin(hour: 20, minute: 0)
                        NotificationManager.shared.scheduleTaskRefresh(hour: 9, minute: 0)
                    }
                }
            }
        }
    }
}
