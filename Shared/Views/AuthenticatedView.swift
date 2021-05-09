//
//  AuthenticatedView.swift
//  TagTime
//
//  Created by Shawn Koh on 7/4/21.
//

import SwiftUI
import Resolver
import Combine

final class AuthenticatedViewModel: ObservableObject {
    enum Page: Hashable {
        case missedPingList
        case logbook
        case goalList
        case statistics
        case preferences
    }

    @Published var isAuthenticated = false
    @Published var isLoggedIntoBeeminder = false
    @Published var pingNotification = AnswerCreatorConfig()
    @Published var currentPage: Page = .missedPingList

    private var subscribers = Set<AnyCancellable>()
    @Injected private var authenticationService: AuthenticationService
    @Injected private var notificationHandler: NotificationHandler
    @Injected private var notificationScheduler: NotificationScheduler
    @Injected private var beeminderCredentialService: BeeminderCredentialService

    init() {
        authenticationService.$user
            .receive(on: DispatchQueue.main)
            .sink { self.isAuthenticated = $0.id != AuthenticationService.unauthenticatedUserId }
            .store(in: &subscribers)

        notificationHandler.$openedPing
            .receive(on: DispatchQueue.main)
            .sink { [self] in
                if let pingDate = $0 {
                    pingNotification.create(pingDate: pingDate)
                } else {
                    pingNotification.dismiss()
                }
            }
            .store(in: &subscribers)

        beeminderCredentialService.$credential
            .receive(on: DispatchQueue.main)
            .sink { [weak self] credential in
                self?.isLoggedIntoBeeminder = credential != nil

                if credential == nil, self?.currentPage == .goalList {
                    self?.currentPage = .missedPingList
                }
            }
            .store(in: &subscribers)
    }
}


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
        AuthenticatedView()
            .preferredColorScheme(.dark)
    }
}
