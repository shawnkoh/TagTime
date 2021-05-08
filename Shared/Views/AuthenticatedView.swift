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
    @Published var pingNotification = AnswerCreatorConfig()
    @Published var currentPage: Page = .missedPingList

    private var subscribers = Set<AnyCancellable>()
    @Injected private var authenticationService: AuthenticationService
    @Injected private var notificationHandler: NotificationHandler
    @Injected private var notificationScheduler: NotificationScheduler
    @Injected private var beeminderCredentialService: BeeminderCredentialService
    @Injected private var alertService: AlertService

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
            .sink { [self] credential in
                if credential == nil, currentPage == .goalList {
                    currentPage = .missedPingList
                }
            }
            .store(in: &subscribers)
    }
}


struct AuthenticatedView: View {
    @StateObject var viewModel = AuthenticatedViewModel()
    @EnvironmentObject var answerService: AnswerService
    @EnvironmentObject var alertService: AlertService
    @EnvironmentObject var beeminderCredentialService: BeeminderCredentialService
    @EnvironmentObject var tagService: TagService

    var isLoggedIntoBeeminder: Bool {
        beeminderCredentialService.credential != nil
    }

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
            if isLoggedIntoBeeminder {
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
                if isLoggedIntoBeeminder {
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
                .environmentObject(self.answerService)
                .environmentObject(self.alertService)
                .environmentObject(self.tagService)
        }
    }
}

struct AuthenticatedView_Previews: PreviewProvider {
    @Injected static var answerService: AnswerService
    @Injected static var alertService: AlertService
    @Injected static var beeminderCredentialService: BeeminderCredentialService
    @Injected static var tagService: TagService

    static var previews: some View {
        AuthenticatedView()
            .preferredColorScheme(.dark)
            .environmentObject(answerService)
            .environmentObject(alertService)
            .environmentObject(beeminderCredentialService)
            .environmentObject(tagService)
    }
}
