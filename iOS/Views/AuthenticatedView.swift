//
//  AuthenticatedView.swift
//  TagTime
//
//  Created by Shawn Koh on 7/4/21.
//

import SwiftUI
import Resolver
import Combine

struct AuthenticatedView: View {
    @StateObject var viewModel = AuthenticatedViewModel()

    // Reference:: https://stackoverflow.com/a/62622935/8639572
    @ViewBuilder
    func page(name: String, destination: AuthenticatedViewModel.Page) -> some View {
        switch viewModel.currentPage == destination {
        case true:
            Image("\(name)-active")
        case false:
            Image(name)
                .onTap { viewModel.currentPage = destination }
                .buttonStyle(UltraPlainButtonStyle())
        }
    }

    var body: some View {
        VStack {
            // Paddings are placed within TabView in order to allow swiping on the edges
            // if statement is used here instead of within TabView because SwiftUI is buggy with it inside.
            if viewModel.isLoggedIntoBeeminder {
                TabView(selection: $viewModel.currentPage) {
                    MissedPingList()
                        .tag(AuthenticatedViewModel.Page.missedPingList)
                        .padding([.top, .leading, .trailing])
                    Logbook()
                        .tag(AuthenticatedViewModel.Page.logbook)
                        .padding([.top, .leading, .trailing])
                    TrackedGoalList()
                        .tag(AuthenticatedViewModel.Page.goalList)
                        .padding([.top, .leading, .trailing])
                    Statistics()
                        .tag(AuthenticatedViewModel.Page.statistics)
                        .padding([.top, .leading, .trailing])
                    Preferences()
                        .tag(AuthenticatedViewModel.Page.preferences)
                        .padding([.top, .leading, .trailing])
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            } else {
                TabView(selection: $viewModel.currentPage) {
                    MissedPingList()
                        .tag(AuthenticatedViewModel.Page.missedPingList)
                        .padding([.top, .leading, .trailing])
                    Logbook()
                        .tag(AuthenticatedViewModel.Page.logbook)
                        .padding([.top, .leading, .trailing])
                    Statistics()
                        .tag(AuthenticatedViewModel.Page.statistics)
                        .padding([.top, .leading, .trailing])
                    Preferences()
                        .tag(AuthenticatedViewModel.Page.preferences)
                        .padding([.top, .leading, .trailing])
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }

            HStack {
                Spacer()
                page(name: "missed-ping-list", destination: .missedPingList)
                page(name: "logbook", destination: .logbook)
                if viewModel.isLoggedIntoBeeminder {
                    page(name: "goal-list", destination: .goalList)
                }
                page(name: "statistics", destination: .statistics)
                Spacer()
                page(name: "preferences", destination: .preferences)
            }
            .padding()
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
            .preferredColorScheme(.dark)
    }
}
