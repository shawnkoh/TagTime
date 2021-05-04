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

@main
struct TagTimeApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject var alertService = AlertService.shared
    @StateObject var answerService = AnswerService.shared
    @StateObject var appService = AppService.shared
    @StateObject var beeminderCredentialService = BeeminderCredentialService.shared
    @StateObject var notificationService = NotificationService.shared
    @StateObject var pingService = PingService.shared
    @StateObject var settingService = SettingService.shared
    @StateObject var tagService = TagService.shared

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
                .environmentObject(beeminderCredentialService)
                .environmentObject(appService)
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
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Initialise Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        UNUserNotificationCenter.current().delegate = NotificationService.shared

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
