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
            Text("Unable to log in.")
            Text("You should not be seeing this page.")
        }
    }
}

struct UnauthenticatedView_Previews: PreviewProvider {
    static var previews: some View {
        UnauthenticatedView()
    }
}
