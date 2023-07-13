//
//  SessionList.swift
//  Astro
//
//  Created by James Wilson on 13/7/2023.
//

import SwiftUI

struct SessionList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedSession: Session.ID?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<Session>

    var body: some View {
        List(selection: $selectedSession) {
            ForEach(sessions) { session in
                Label(session.dateString!, systemImage: "leaf")
            }
        }
        .frame(minWidth: 250)
    }
}

struct SessionList_Previews: PreviewProvider {
    static var previews: some View {
        SessionList()
    }
}
