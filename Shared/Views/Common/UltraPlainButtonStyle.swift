//
//  UltraPlainButtonStyle.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI

// Credit: https://stackoverflow.com/questions/65047746/swiftui-unexpected-behaviour-using-ontapgesture-with-mouse-trackpad-on-ipados
public struct UltraPlainButtonStyle: ButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}
