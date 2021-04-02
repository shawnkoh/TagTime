//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MissedPingList(pings: Stub.pings)
            Logbook(answers: Stub.answers)
            Statistics()
            Preferences()
        }
        .tabViewStyle(PageTabViewStyle())
        .background(Color.black)
        .foregroundColor(Color.white)
        .statusBar(hidden: true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
