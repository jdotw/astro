//
//  SessionList.swift
//  Astro
//
//  Created by James Wilson on 13/7/2023.
//

import SwiftUI

struct SessionList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selection: Session?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<Session>

    var body: some View {
        List(selection: $selection) {
            ForEach(sessions, id: \.self) { session in
                Label(session.dateString, systemImage: "moon")
            }
        }
    }
}
