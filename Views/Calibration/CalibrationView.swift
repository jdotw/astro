//
//  CalibrationView.swift
//  Astro
//
//  Created by James Wilson on 17/9/2023.
//

import SwiftUI

struct CalibrationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: true)],
        predicate: NSPredicate(format: "SUBQUERY(files, $file, $file.type =[cd] 'Light' AND $file.calibrationSession = nil) .@count > 0"),
        animation: .default)
    private var uncalibratedSessions: FetchedResults<Session>

    @State private var selectedSessions: Set<Session> = []

    var body: some View {
        List(selection: $selectedSessions) {
            ForEach(uncalibratedSessions, id: \.self) { session in

                VStack(alignment: .leading) {
                    Text(session.dateString)
                    Text(session.uniqueUncalibratedFilterNames.joined(separator: ", "))
                }.draggable(session.objectID.uriRepresentation())
            }
        }
    }
}

extension Session {
    var uniqueUncalibratedFilterNames: [String] {
        guard let files = files?.allObjects as? [File] else { return [] }
        let filters = files.compactMap { $0.calibrationSession != nil ? nil : $0.filter }
        return Array(Set(filters)).sorted()
    }
}
