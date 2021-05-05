//
//  Card.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI

struct Card: View {
    let text: String

    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .foregroundColor(.primary)
                .padding()
            Spacer()
        }
        .background(Color.hsb(213, 24, 18))
        .cornerRadius(8)
    }
}

struct Card_Previews: PreviewProvider {
    static var previews: some View {
        Card(text: "Abc")
    }
}
