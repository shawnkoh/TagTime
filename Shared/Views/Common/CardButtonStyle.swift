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
        HStack {
            Spacer()
            configuration.label
                .padding()
                .foregroundColor(.white)
            Spacer()
        }
        .background(backgroundColor)
        .cornerRadius(8)
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

extension View {
    func cardButtonStyle(_ backgroundColor: Color) -> some View {
        self.buttonStyle(CardButtonStyle(backgroundColor))
    }
}
