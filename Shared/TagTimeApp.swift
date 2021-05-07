//
//  TagTimeApp.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase
import UserNotifications
import FBSDKCoreKit
import Resolver

@main
struct TagTimeApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject var alertService: AlertService = Resolver.resolve()
    @StateObject var answerService: AnswerService = Resolver.resolve()
    @StateObject var appService: AppService = Resolver.resolve()
    @StateObject var beeminderCredentialService: BeeminderCredentialService = Resolver.resolve()
    @StateObject var facebookLoginService: FacebookLoginService = Resolver.resolve()
    @StateObject var goalService: GoalService = Resolver.resolve()
    @StateObject var notificationService: NotificationService = Resolver.resolve()
    @StateObject var pingService: PingService = Resolver.resolve()
    @StateObject var settingService: SettingService = Resolver.resolve()
    @StateObject var tagService: TagService = Resolver.resolve()

    init() {
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert(isPresented: $alertService.isPresented) {
                    Alert(title: Text(alertService.message))
                }
                .environmentObject(alertService)
                .environmentObject(answerService)
                .environmentObject(appService)
                .environmentObject(beeminderCredentialService)
                .environmentObject(facebookLoginService)
                .environmentObject(goalService)
                .environmentObject(notificationService)
                .environmentObject(pingService)
                .environmentObject(settingService)
                .environmentObject(tagService)
                .onAppear() { appService.signIn() }
                .statusBar(hidden: true)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    @Injected private var notificationService: NotificationService

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Initialise Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        UNUserNotificationCenter.current().delegate = notificationService

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Initialise Facebook SDK
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
}
