//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase
import Resolver

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
    @Injected static var appService: AppService

    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
            .environmentObject(appService)
    }
}
