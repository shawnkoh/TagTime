//
//  Tappable.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 26/4/21.
//

import Foundation
import SwiftUI

// Credit: https://stackoverflow.com/questions/65047746/swiftui-unexpected-behaviour-using-ontapgesture-with-mouse-trackpad-on-ipados
public struct UltraPlainButtonStyle: ButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}

struct Tappable: ViewModifier {
    let action: () -> ()

    func body(content: Content) -> some View {
        Button(action: self.action) {
            content
        }
        .buttonStyle(UltraPlainButtonStyle())
    }
}

extension View {
    func tappable(do action: @escaping () -> ()) -> some View {
        self.modifier(Tappable(action: action))
    }
}
