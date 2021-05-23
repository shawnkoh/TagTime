//
//  Preferences.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI
import Resolver
import Combine
import AuthenticationServices
import UniformTypeIdentifiers

final class PreferencesViewModel: ObservableObject {
    @LazyInjected private var settingService: SettingService
    #if os(iOS)
    @LazyInjected private var facebookLoginService: FacebookLoginService
    #endif
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var alertService: AlertService
    @LazyInjected private var appleLoginService: AppleLoginService
    @LazyInjected private var answerBuilderExecutor: AnswerBuilderExecutor

    @Published private(set) var isLoggedIntoApple = false
    @Published private(set) var isLoggedIntoFacebook = false
    @Published var averagePingInterval: Int = 45
    @Published private(set) var uid = ""

    private var subscribers = Set<AnyCancellable>()

    var allowedContentTypes: [UTType] { [.init(filenameExtension: "log")!] }

    init() {
        settingService.$averagePingInterval
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.averagePingInterval = $0 }
            .store(in: &subscribers)

        authenticationService.userPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.uid = user.id
                self?.isLoggedIntoApple = user.providers.contains(.apple)
                self?.isLoggedIntoFacebook = user.providers.contains(.facebook)
            }
            .store(in: &subscribers)
    }

    #if os(iOS)
    func loginWithFacebook() {
        facebookLoginService.login()
    }
    #endif

    func unlink(from provider: AuthProvider) {
        authenticationService
            .unlink(from: provider)
            .errorHandled(by: alertService)
    }

    func linkWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case let .failure(error):
            alertService.present(message: error.localizedDescription)
        case let .success(authorization):
            authenticationService
                .linkWithApple(authorization: authorization)
                .errorHandled(by: alertService)
        }
    }

    func getHashedNonce() -> String {
        appleLoginService.getHashedNonce()
    }

    // TODO: This reads the entire file into memory. Should be ok for most use cases but
    // might crash for Daniel's 13 year data.
    func importLogs(_ logs: Result<URL, Error>) {
        switch logs {
        case let .failure(error):
            alertService.present(message: error.localizedDescription)
        case let .success(url):
            guard
                let data = try? Data(contentsOf: url),
                let logs = String(data: data, encoding: .utf8)
            else {
                return
            }
            var answerBuilder = AnswerBuilder()
            _ = answerBuilder.updateTrackedGoals(false)
            logs
                .components(separatedBy: .newlines)
                .filter { $0.count > 0 }
                .forEach { entry in
                    let relevantWords = entry.split(separator: "[")
                    guard relevantWords.count > 0 else {
                        return
                    }
                    var tags = relevantWords[0]
                        .split(separator: " ")
                        .map { $0.lowercased() }
                    let unixtime = tags.removeFirst()
                    guard let unixtime = TimeInterval(unixtime) else {
                        return
                    }
                    let ping = Date(timeIntervalSince1970: unixtime)

                    let answer = Answer(ping: ping, tags: tags)
                    _ = answerBuilder.createAnswer(answer)
                }
            answerBuilder
                .execute(with: answerBuilderExecutor)
                .errorHandled(by: alertService)
        }
    }
}

struct Preferences: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @State private var isImporting = false

    #if DEBUG
    @State private var isDebugPresented = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageTitle(title: "Preferences", subtitle: "Suit yourself")

            VStack(alignment: .leading) {
//                Text("Ping Interval (minutes)")
//                    .bold()
//
//                TextField(
//                    "Ping Interval",
//                    value: $viewModel.averagePingInterval,
//                    formatter: NumberFormatter(),
//                    onEditingChanged: { _ in },
//                    onCommit: {}
//                )

                BeeminderLoginButton()

                if viewModel.isLoggedIntoApple {
                    Text("Logout from Apple")
                        .onTap { viewModel.unlink(from: .apple) }
                } else {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .fullName]
                            request.nonce = viewModel.getHashedNonce()
                        },
                        onCompletion: viewModel.linkWithApple
                    )
                }

                #if os(iOS)
                if viewModel.isLoggedIntoFacebook {
                    Text("Logout from Facebook")
                        .onTap { viewModel.unlink(from: .facebook) }
                } else {
                    Text("Login with Facebook")
                        .onTap { viewModel.loginWithFacebook() }
                }
                #endif

                Text("Import logs from TagTimePerl")
                    .onTap { isImporting = true }
                    .fileImporter(
                        isPresented: $isImporting,
                        allowedContentTypes: viewModel.allowedContentTypes,
                        onCompletion: viewModel.importLogs
                    )

                #if DEBUG
                Text("Open Debug Menu")
                    .onTap { isDebugPresented = true }
                    .popover(isPresented: $isDebugPresented, arrowEdge: .bottom) {
                        DebugMenu()
                    }

                Text("UID: \(viewModel.uid)")
                    .cardStyle(.modalCard)
                #endif
            }
            Spacer()
        }
        .cardButtonStyle(.baseCard)
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return Preferences()
    }
}
