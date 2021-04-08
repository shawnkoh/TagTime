//
//  Statistics.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct Statistics: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Statistics", subtitle: "Quantified Self")
        }
    }
}

struct Statistics_Previews: PreviewProvider {
    static var previews: some View {
        Statistics()
            .environmentObject(Stub.store)
    }
}
