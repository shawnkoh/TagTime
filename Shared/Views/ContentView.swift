//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @State var user: User?

    var body: some View {
        if let user = user {
            AuthenticatedView()
                .environmentObject(Store(user: user))
        } else {
            UnauthenticatedView()
                .onAppear() {
                    if let user = Auth.auth().currentUser {
                        self.user = .init(user: user)
                    } else {
                        signInAnonymously()
                    }
                }
        }
    }

    private func signInAnonymously() {
        Auth.auth().signInAnonymously() { (result, error) in
            guard let result = result else {
                // TODO: Find a way to display this
                print("unable to sign in anonymously", error?.localizedDescription as Any)
                return
            }
            self.user = .init(user: result.user)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Settings())
            .environmentObject(Store(user: Stub.user))
            .preferredColorScheme(.dark)
    }
}

extension User {
    init(user: Firebase.User) {
        self.id = user.uid
    }
}
