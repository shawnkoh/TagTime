//
//  Tappable.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 26/4/21.
//

import Foundation
import SwiftUI

struct Tappable: ViewModifier {
    let action: () -> ()

    func body(content: Content) -> some View {
        Button(action: self.action) {
            content
        }
    }
}

extension View {
    func onTap(perform action: @escaping () -> ()) -> some View {
        self.modifier(Tappable(action: action))
    }
}
