//
//  DoubleTappable.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import Foundation
import SwiftUI

struct DoubleTappable: ViewModifier {
    let confirmationText: String
    let action: () -> ()

    @State var isTapped = false

    func body(content: Content) -> some View {
        Button(action: tap) {
            if isTapped {
                Text(confirmationText)
            } else {
                content
            }
        }
    }

    private func tap() {
        if isTapped {
            action()
        } else {
            isTapped = true
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                isTapped = false
            }
        }
    }
}

extension View {
    func onDoubleTap(_ confirmationText: String, perform action: @escaping () -> ()) -> some View {
        self.modifier(DoubleTappable(confirmationText: confirmationText, action: action))
    }
}
