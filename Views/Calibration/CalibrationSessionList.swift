//
//  CalibrationSessionList.swift
//  Astro
//
//  Created by James Wilson on 17/9/2023.
//

import SwiftUI

struct CalibrationSessionList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: true)],
        predicate: NSPredicate(format: "ANY files.type =[cd] %@", "Flat"),
        animation: .default)
    private var calibrationSessions: FetchedResults<Session>

    @State private var selectedSession: Session?

    var body: some View {
        List(selection: $selectedSession) {
            ForEach(calibrationSessions, id: \.self) { session in
                CalibrationSessionView(session: session)
            }
        }
    }
}

extension Session {
    var uniqueFilterNames: [String] {
        let files = files?.allObjects as? [File]
        let filterNames = files?.compactMap { $0.filter }
        guard let filterNames else { return [] }
        return Array(Set(filterNames)).sorted()
    }
}
