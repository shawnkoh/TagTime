//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI

struct ContentView: View {
    enum Page: Hashable {
        case missedPingList
        case logbook
        case statistics
        case preferences
    }

    @State private var currentPage: Page = .missedPingList

    // Reference:: https://stackoverflow.com/a/62622935/8639572
    @ViewBuilder
    func page(name: String, destination: Page) -> some View {
        switch currentPage == destination {
        case true:
            Image("\(name)-active")
        case false:
            Image(name)
                .onTapGesture { currentPage = destination }
        }
    }

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                MissedPingList()
                    .tag(Page.missedPingList)
                Logbook()
                    .tag(Page.logbook)
                Statistics()
                    .tag(Page.statistics)
                Preferences()
                    .tag(Page.preferences)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            HStack {
                Spacer()
                page(name: "missed-ping-list", destination: .missedPingList)
                page(name: "logbook", destination: .logbook)
                page(name: "statistics", destination: .statistics)
                Spacer()
                page(name: "preferences", destination: .preferences)
            }
        }
        .statusBar(hidden: true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Settings())
            .environmentObject(ModelData())
            .preferredColorScheme(.dark)
    }
}
