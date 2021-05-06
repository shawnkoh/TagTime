//
//  CardModifier.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI

struct CardStyle: ViewModifier {
    let backgroundColor: Color

    init(_ backgroundColor: Color) {
        self.backgroundColor = backgroundColor
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
                .padding()
                .foregroundColor(.white)
            Spacer()
        }
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

extension View {
    func cardStyle(_ backgroundColor: Color) -> some View {
        self.modifier(CardStyle(backgroundColor))
    }
}
