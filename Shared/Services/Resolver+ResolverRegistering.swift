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
        register { AnswerService() }
            .scope(.cached)
        register { AuthenticationService() }
            .scope(.cached)
        register { BeeminderCredentialService() }
            .scope(.cached)
        register { FacebookLoginService() }
            .scope(.cached)
        register { GoalService() }
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
