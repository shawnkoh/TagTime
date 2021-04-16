//
//  AuthenticatedView.swift
//  TagTime
//
//  Created by Shawn Koh on 7/4/21.
//

import SwiftUI

struct AuthenticatedView: View {
    enum Page: Hashable {
        case missedPingList
        case logbook
        case statistics
        case preferences
    }

    @EnvironmentObject var store: Store
    @EnvironmentObject var alertService: AlertService

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
        .alert(isPresented: $alertService.isPresented) {
            Alert(title: Text(alertService.message))
        }
    }
}

struct AuthenticatedView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedView()
            .environmentObject(Stub.settingService)
            .environmentObject(Stub.store)
            .preferredColorScheme(.dark)
    }
}
