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
import Combine

final class AppViewModel: ObservableObject {
    @Injected private var beeminderCredentialService: BeeminderCredentialService
    @Injected private var alertService: AlertService
    @Injected private var authenticationService: AuthenticationService

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

    func signIn() {
        // TODO: I'm not sure if Futures should be called in async thread
        DispatchQueue.global(qos: .utility).async { [self] in
            authenticationService.signIn()
                .setUser(service: authenticationService)
                .errorHandled(by: alertService)
        }
    }
}

@main
struct TagTimeApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
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
                .alert(isPresented: $viewModel.isAlertPresented) {
                    Alert(title: Text(viewModel.alertMessage))
                }
                .onAppear() { viewModel.signIn() }
                .statusBar(hidden: true)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    @Injected private var notificationHandler: NotificationHandler

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
