//
//  AuthenticatedView.swift
//  TagTime
//
//  Created by Shawn Koh on 7/4/21.
//

import SwiftUI

struct AuthenticatedView: View {
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var answerService: AnswerService
    @EnvironmentObject var alertService: AlertService
    @EnvironmentObject var beeminderService: BeeminderService
    @EnvironmentObject var tagService: TagService

    var isLoggedIntoBeeminder: Bool {
        beeminderService.credential != nil
    }

    // Reference:: https://stackoverflow.com/a/62622935/8639572
    @ViewBuilder
    func page(name: String, destination: AppService.Page) -> some View {
        switch appService.currentPage == destination {
        case true:
            Image("\(name)-active")
        case false:
            Image(name)
                .tappable { appService.currentPage = destination }
        }
    }

    var body: some View {
        VStack {
            if isLoggedIntoBeeminder {
                TabView(selection: $appService.currentPage) {
                    MissedPingList()
                        .tag(AppService.Page.missedPingList)
                    Logbook()
                        .tag(AppService.Page.logbook)
                    GoalList()
                        .tag(AppService.Page.goalList)
                    Statistics()
                        .tag(AppService.Page.statistics)
                    Preferences()
                        .tag(AppService.Page.preferences)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            } else {
                TabView(selection: $appService.currentPage) {
                    MissedPingList()
                        .tag(AppService.Page.missedPingList)
                    Logbook()
                        .tag(AppService.Page.logbook)
                    Statistics()
                        .tag(AppService.Page.statistics)
                    Preferences()
                        .tag(AppService.Page.preferences)
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
        }
        .sheet(isPresented: $appService.pingNotification.isPresented) {
            AnswerCreator(config: $appService.pingNotification)
                .environmentObject(self.answerService)
                .environmentObject(self.alertService)
                .environmentObject(self.tagService)
        }
    }
}

struct AuthenticatedView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedView()
            .preferredColorScheme(.dark)
            .environmentObject(AppService.shared)
            .environmentObject(AnswerService.shared)
            .environmentObject(AlertService.shared)
    }
}
