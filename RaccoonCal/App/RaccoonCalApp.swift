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
    }
}
