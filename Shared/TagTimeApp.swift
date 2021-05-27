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
    @LazyInjected private var firebaseService: FirebaseService
    @LazyInjected private var alertService: AlertService
    @LazyInjected private var router: Router

    @Published var isAlertPresented = false
    @Published private(set) var alertMessage = ""

    private var subscribers = Set<AnyCancellable>()

    init() {
        firebaseService.configure()

        alertService.$isPresented
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAlertPresented = $0 }
            .store(in: &subscribers)

        alertService.$message
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.alertMessage = $0 }
            .store(in: &subscribers)
    }

    func changePage(to page: Router.Page) {
        router.currentPage = page
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

    init() {}

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modify {
                    #if os(iOS)
                    $0.statusBar(hidden: true)
                    #else
                    $0.frame(minWidth: 880, minHeight: 500)
                    #endif
                }
                .alert(isPresented: $viewModel.isAlertPresented) {
                    Alert(title: Text(viewModel.alertMessage))
                }
        }
        .commands {
            CommandGroup(after: .sidebar) {
                Button("Show Missed Pings") {
                    viewModel.changePage(to: .missedPingList)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Show Logbook") {
                    viewModel.changePage(to: .logbook)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Show Goals") {
                    viewModel.changePage(to: .goalList)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Show Statistics") {
                    viewModel.changePage(to: .statistics)
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("Show Preferences") {
                    viewModel.changePage(to: .preferences)
                }
                .keyboardShortcut("5", modifiers: .command)
            }
        }
    }
}

#if os(macOS)
// Reference:: https://www.anaghsharma.com/blog/macos-menu-bar-app-with-swiftui/
class StatusBarController {
    private var statusBar = NSStatusBar()
    private var statusItem: NSStatusItem

    init() {
        statusItem = statusBar.statusItem(withLength: 28.0)

        guard let button = statusItem.button else {
            return
        }
        button.image = #imageLiteral(resourceName: "status-bar")
        button.action = #selector(togglePopup)
        button.target = self
        button.image?.isTemplate = true
    }

    @objc private func togglePopup() {
        if NSApp.isActive {
            NSApp.hide(nil)
        } else {
            if let window = NSApp.windows.first {
                window.collectionBehavior = .canJoinAllSpaces
                window.center()
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.setActivationPolicy(.accessory)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
#endif

final class AppDelegate: NSObject {
    @LazyInjected private var notificationHandler: NotificationHandler

    #if os(macOS)
    var statusBar: StatusBarController?
    #endif
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
extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = notificationHandler
        statusBar = .init()
    }
}
#endif
