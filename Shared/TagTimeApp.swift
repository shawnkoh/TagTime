//
//  TagTimeApp.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase
import UserNotifications
import Resolver
import Combine
#if os(iOS)
import FacebookCore
#endif

final class AppViewModel: ObservableObject {
    @Injected private var alertService: AlertService

    @Published var isAlertPresented = false
    @Published private(set) var alertMessage = ""

    private var subscribers = Set<AnyCancellable>()

    init() {
        alertService.$isPresented
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAlertPresented = $0 }
            .store(in: &subscribers)

        alertService.$message
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.alertMessage = $0 }
            .store(in: &subscribers)
    }
}

@main
struct TagTimeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #else
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    @StateObject private var viewModel = AppViewModel()

    init() {
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modify {
                    #if os(iOS)
                    $0.statusBar(hidden: true)
                    #else
                    $0.frame(minWidth: 550, minHeight: 500)
                    #endif
                }
                .alert(isPresented: $viewModel.isAlertPresented) {
                    Alert(title: Text(viewModel.alertMessage))
                }
        }
    }
}

final class AppDelegate: NSObject {
    @Injected private var notificationHandler: NotificationHandler
}

#if os(iOS)
extension AppDelegate: UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Initialise Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        UNUserNotificationCenter.current().delegate = notificationHandler

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
#endif

#if os(macOS)
extension AppDelegate: NSApplicationDelegate {}
#endif
