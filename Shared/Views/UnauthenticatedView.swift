//
//  UnauthenticatedView.swift
//  TagTime
//
//  Created by Shawn Koh on 7/4/21.
//

import SwiftUI

struct UnauthenticatedView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("TAGTIME")
                .bold()
                .font(.largeTitle)
            Spacer()
        }
    }
}

struct UnauthenticatedView_Previews: PreviewProvider {
    static var previews: some View {
        UnauthenticatedView()
    }
}
