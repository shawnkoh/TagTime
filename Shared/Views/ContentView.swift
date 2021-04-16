//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @EnvironmentObject var appService: AppService

    var body: some View {
        if appService.isAuthenticated {
            AuthenticatedView()
        } else {
            UnauthenticatedView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    private static let settings = SettingService()

    static var previews: some View {
        ContentView()
            .environmentObject(AppService.shared)
            .preferredColorScheme(.dark)
    }
}
