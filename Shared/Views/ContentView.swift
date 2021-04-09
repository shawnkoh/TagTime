//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore

struct ContentView: View {
    @State var user: User?
    @EnvironmentObject var settings: Settings

    var body: some View {
        if let user = user {
            AuthenticatedView()
                .environmentObject(Store(settings: settings, user: user))
        } else {
            UnauthenticatedView()
                .onAppear() {
                    if let user = Auth.auth().currentUser {
                        getUser(id: user.uid)
                    } else {
                        signInAnonymously()
                    }
                }
        }
    }

    private func setupUser(id: String) {
        let user = User(id: id, startDate: Date())
        do {
            try Firestore.firestore()
                .collection("users")
                .document(user.id)
                .setData(from: user) { error in
                    if let error = error {
                        print(error)
                    } else {
                        self.user = user
                    }
                }
        } catch {
            // TODO: Handle this
            print("Unable to save user", user)
        }
    }

    private func getUser(id: String) {
        Firestore.firestore()
            .collection("users")
            .document(id)
            .getDocument() { (snapshot, error) in
                do {
                    guard let user = try snapshot?.data(as: User.self) else {
                        setupUser(id: id)
                        return
                    }
                    self.user = user
                } catch {
                    // TODO: Handle this
                    print("Unable to get user")
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
            setupUser(id: result.user.uid)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    private static let settings = Settings()

    static var previews: some View {
        ContentView()
            .environmentObject(settings)
            .environmentObject(Stub.store)
            .preferredColorScheme(.dark)
    }
}
