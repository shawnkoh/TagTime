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
    private func page(label: String, image: String, destination: Router.Page) -> some View {
        HStack {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(2)
                .frame(width: 20, height: 20)
                .fixedSize()
            Text(label)
        }
    }

    var body: some View {
        NavigationView {
            List(selection: $viewModel.currentPage) {
                NavigationLink(
                    destination: MissedPingList().padding([.top, .leading, .trailing]),
                    tag: Router.Page.missedPingList,
                    selection: $viewModel.currentPage
                ) {
                    page(label: "Missed Pings", image: "missed-ping-list", destination: .missedPingList)
                }
                .tag(Router.Page.missedPingList)

                NavigationLink(
                    destination: Logbook().padding([.top, .leading, .trailing]),
                    tag: Router.Page.logbook,
                    selection: $viewModel.currentPage
                ) {
                    page(label: "Logbook", image: "logbook", destination: .logbook)
                }
                .tag(Router.Page.logbook)

                if viewModel.isLoggedIntoBeeminder {
                    NavigationLink(
                        destination: TrackedGoalList(),
                        tag: Router.Page.goalList,
                        selection: $viewModel.currentPage
                    ) {
                        // Intentional (for now while the active image has thicker borders).
                        page(label: "Goals", image: "goal-list-active", destination: .goalList)
                    }
                    .tag(Router.Page.goalList)
                }

                NavigationLink(
                    destination: Statistics().padding([.top, .leading, .trailing]),
                    tag: Router.Page.statistics,
                    selection: $viewModel.currentPage
                ) {
                    page(label: "Statistics", image: "statistics", destination: .statistics)
                }
                .tag(Router.Page.statistics)

                NavigationLink(
                    destination: Preferences().padding([.top, .leading, .trailing]),
                    tag: Router.Page.preferences,
                    selection: $viewModel.currentPage
                ) {
                    page(label: "Preferences", image: "preferences", destination: .preferences)
                }
                .tag(Router.Page.preferences)
            }
            .listStyle(SidebarListStyle())
        }
        .sheet(isPresented: $viewModel.pingNotification.isPresented) {
            AnswerCreator(config: $viewModel.pingNotification)
                .background(Color.modalBackground)
        }
    }
}

#if DEBUG
struct AuthenticatedView_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.root = .mock
        return AuthenticatedView()
    }
}
#endif
