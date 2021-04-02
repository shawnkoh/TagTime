//
//  Preferences.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct Preferences: View {
    @State private var samplingInterval: Int = 45

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Preferences")
                    .font(.title)
                Text("Suit yourself")
                    .font(.subheadline)
            }

            HStack {
                Text("Sampling Interval")
                    .bold()
                TextField("ABC", value: $samplingInterval, formatter: NumberFormatter())
            }
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        Preferences()
    }
}
