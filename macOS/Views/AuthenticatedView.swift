//
//  AuthenticatedView.swift
//  TagTime
//
//  Created by Shawn Koh on 13/5/21.
//

import SwiftUI
import Resolver

struct AuthenticatedView: View {
    @StateObject var viewModel = AuthenticatedViewModel()

    // Reference:: https://stackoverflow.com/a/62622935/8639572
    @ViewBuilder
    private func page(label: String, image: String, destination: AuthenticatedViewModel.Page) -> some View {
        switch viewModel.currentPage == destination {
        case true:
            Label(label, image: "\(image)-active")
        case false:
            Label(label, image: image)
        }
    }

    var body: some View {
        NavigationView {
            List(selection: $viewModel.currentPage) {
                NavigationLink(
                    destination: MissedPingList().padding([.top, .leading, .trailing]),
                    tag: AuthenticatedViewModel.Page.missedPingList,
                    selection: $viewModel.currentPage
                ) {
                    page(label: "Missed Pings", image: "missed-ping-list", destination: .missedPingList)
                }
                .tag(AuthenticatedViewModel.Page.missedPingList)

                NavigationLink(
                    destination: Logbook().padding([.top, .leading, .trailing]),
                    tag: AuthenticatedViewModel.Page.logbook,
                    selection: $viewModel.currentPage
                ) {
                    page(label: "Logbook", image: "logbook", destination: .logbook)
                }
                .tag(AuthenticatedViewModel.Page.logbook)

                if viewModel.isLoggedIntoBeeminder {
                    NavigationLink(
                        destination: TrackedGoalList().padding([.top, .leading, .trailing]),
                        tag: AuthenticatedViewModel.Page.goalList,
                        selection: $viewModel.currentPage
                    ) {
                        page(label: "Goals", image: "goal-list", destination: .goalList)
                    }
                    .tag(AuthenticatedViewModel.Page.goalList)
                }

                NavigationLink(
                    destination: Statistics().padding([.top, .leading, .trailing]),
                    tag: AuthenticatedViewModel.Page.statistics,
                    selection: $viewModel.currentPage
                ) {
                    page(label: "Statistics", image: "statistics", destination: .statistics)
                }
                .tag(AuthenticatedViewModel.Page.statistics)

                NavigationLink(
                    destination: Preferences().padding([.top, .leading, .trailing]),
                    tag: AuthenticatedViewModel.Page.preferences,
                    selection: $viewModel.currentPage
                ) {
                    page(label: "Preferences", image: "preferences", destination: .preferences)
                }
                .tag(AuthenticatedViewModel.Page.preferences)
            }
        }
        .sheet(isPresented: $viewModel.pingNotification.isPresented) {
            AnswerCreator(config: $viewModel.pingNotification)
                .background(Color.modalBackground)
        }
    }
}

struct AuthenticatedView_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return AuthenticatedView()
    }
}
