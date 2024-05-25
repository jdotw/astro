//
//  SessionList.swift
//  Astro
//
//  Created by James Wilson on 13/7/2023.
//

import SwiftUI

struct SessionList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedSessionID: URL?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<Session>

    var body: some View {
        List(selection: $selectedSessionID) {
            ForEach(sessions) { session in
                Label(session.date.formatted(date: .abbreviated, time: .omitted), systemImage: "moon")
            }
        }
    }
}
