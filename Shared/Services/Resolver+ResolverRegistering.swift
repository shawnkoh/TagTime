//
//  Resolver.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 7/5/21.
//

import Foundation
import Resolver

extension Resolver: ResolverRegistering {
    #if DEBUG
    static let mock = Resolver(parent: main)
    #endif

    public static func registerAllServices() {
        //MARK: Common

        register { AlertService() }
            .scope(.cached)

        register { AppleLoginService() }
            .scope(.cached)

        register { AnswerablePingService() }
            .scope(.cached)

        register { Router() }
            .scope(.cached)

        #if os(iOS)
        register { FacebookLoginService() }
            .scope(.cached)
        #endif

        register { NotificationHandler() }
            .scope(.cached)

        register { NotificationScheduler() }
            .scope(.cached)

        register { OpenPingService() }
            .scope(.cached)

        register { PingService() }
            .scope(.cached)

        register { SettingService() }
            .scope(.cached)

        // MARK: Firestore

        register { RealFirebaseService() }
            .implements(FirebaseService.self)
            .scope(.application)

        register { FirestoreAnswerService() }
            .implements(AnswerService.self)
            .scope(.cached)

        register { FirestoreAnswerBuilderExecutor() }
            .implements(AnswerBuilderExecutor.self)
            .scope(.cached)

        register { FirestoreAuthenticationService() }
            .implements(AuthenticationService.self)
            .scope(.cached)

        register { FirestoreBeeminderCredentialService() }
            .implements(BeeminderCredentialService.self)
            .scope(.cached)

        register { FirestoreGoalService() }
            .implements(GoalService.self)
            .scope(.cached)

        register { FirestoreTagService() }
            .implements(TagService.self)
            .scope(.cached)

        // MARK: Mock

        #if DEBUG
        mock.register { MockFirebaseService() }
            .implements(FirebaseService.self)
            .scope(.application)

        mock.register { MockAnswerService() }
            .implements(AnswerService.self)
            .scope(.cached)

        mock.register { MockAnswerBuilderExecutor() }
            .implements(AnswerBuilderExecutor.self)
            .scope(.cached)

        mock.register { MockAuthenticationService() }
            .implements(AuthenticationService.self)
            .scope(.cached)

        mock.register { MockBeeminderCredentialService() }
            .implements(BeeminderCredentialService.self)
            .scope(.cached)

        mock.register { MockGoalService() }
            .implements(GoalService.self)
            .scope(.cached)

        mock.register { MockTagService() }
            .implements(TagService.self)
            .scope(.cached)
        #endif
    }
}
