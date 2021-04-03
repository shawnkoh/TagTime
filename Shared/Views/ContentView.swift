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

    @EnvironmentObject var modelData: ModelData

    // Cache the images so they don't get rendered again.
    // Not sure just how useful it is though.
    // TODO: Test its performance
    // This was added initially when TabView was lagging badly. The lag was solved
    // by using TabView(selection:) rather than just TabView.
    static let missedPingListImage = Image("missed-ping-list")
    static let missedPingListActiveImage = Image("missed-ping-list-active")

    static let logbookImage = Image("logbook")
    static let logbookActiveImage = Image("logbook-active")

    static let statisticsImage = Image("statistics")
    static let statisticsActiveImage = Image("statistics-active")

    static let preferencesImage = Image("preferences")
    static let preferencesActiveImage = Image("preferences-active")

    @State private var currentPage: Page = .missedPingList

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
                (currentPage == .missedPingList ? Self.missedPingListActiveImage : Self.missedPingListImage)
                    .onTapGesture { currentPage = .missedPingList }
                (currentPage == .logbook ? Self.logbookActiveImage : Self.logbookImage)
                    .onTapGesture { currentPage = .logbook }
                (currentPage == .statistics ? Self.statisticsActiveImage : Self.statisticsImage)
                    .onTapGesture { currentPage = .statistics }
                Spacer()
                (currentPage == .preferences ? Self.preferencesActiveImage : Self.preferencesImage)
                    .onTapGesture { currentPage = .preferences }
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
