//
//  CardButtonStyle.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI

struct CardButtonStyle: ButtonStyle {
    let backgroundColor: Color

    init(_ backgroundColor: Color) {
        self.backgroundColor = backgroundColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .cardStyle(backgroundColor)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

extension View {
    func cardButtonStyle(_ backgroundColor: Color) -> some View {
        self.buttonStyle(CardButtonStyle(backgroundColor))
    }
}
