//
//  TagTimeApp.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase
import UserNotifications

// Required to pass instance to AppDelegate
let globalStore = Store()

@main
struct TagTimeApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject var store = globalStore
    @StateObject var alertService = AlertService.shared
    @StateObject var answerService = AnswerService.shared
    @StateObject var authenticationService = AuthenticationService.shared
    // @StateObject var notificationService = NotificationService.shared
    @StateObject var pingService = PingService.shared
    @StateObject var settingService = SettingService.shared

    init() {
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alertService)
                .environmentObject(answerService)
                .environmentObject(authenticationService)
//                .environmentObject(notificationService)
                .environmentObject(pingService)
                .environmentObject(settingService)
                .onAppear() {
                    DispatchQueue.global(qos: .utility).async {
                        _ = AuthenticationService.shared.signIn()
                    }
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = globalStore.notificationService
        return true
    }
}
