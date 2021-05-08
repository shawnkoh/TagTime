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
    @EnvironmentObject var authenticationService: AuthenticationService

    var body: some View {
        if authenticationService.isAuthenticated {
            AuthenticatedView()
        } else {
            UnauthenticatedView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
