//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        if store.authenticationService.user != nil {
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
            .environmentObject(Stub.store)
            .preferredColorScheme(.dark)
    }
}
