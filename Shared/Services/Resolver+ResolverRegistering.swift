//
//  Resolver.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 7/5/21.
//

import Foundation
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { AlertService() }
            .scope(.cached)
        register { FirestoreAnswerService() }
            .implements(AnswerService.self)
            .scope(.cached)
        register { AnswerablePingService() }
            .scope(.cached)
        register { FirestoreAuthenticationService() }
            .implements(AuthenticationService.self)
            .scope(.cached)
        register { FirestoreBeeminderCredentialService() }
            .implements(BeeminderCredentialService.self)
            .scope(.cached)
        register { FacebookLoginService() }
            .scope(.cached)
        register { FirestoreGoalService() }
            .implements(GoalService.self)
            .scope(.cached)
        register { NotificationHandler() }
            .scope(.cached)
        register { NotificationScheduler() }
            .scope(.cached)
        register { PingService() }
            .scope(.cached)
        register { SettingService() }
            .scope(.cached)
        register { TagService() }
            .scope(.cached)
    }
}
