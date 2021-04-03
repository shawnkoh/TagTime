//
//  PageTitle.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import SwiftUI

struct PageTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .bold()
                .font(.title)
            Text(subtitle)
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }
}

struct PageTitle_Previews: PreviewProvider {
    static var previews: some View {
        PageTitle(title: "Pings", subtitle: "Missed pings")
    }
}
