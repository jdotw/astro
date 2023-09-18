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
                VStack(alignment: .leading) {
                    Text(session.dateString)
                    Text(session.uniqueFilterNames.joined(separator: ", "))
                }
                .dropDestination(for: URL.self) { items, location in
                    var acceptDrop = false
                    var sessions = [Session]()
                    print("DROP items=\(items) location=\(location) to=\(session.dateString)")
                    for url in items {
                        guard let droppedObjectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else { continue }
                        let droppedObject = viewContext.object(with: droppedObjectID)
                        switch droppedObject {
                        case let session as Session:
                            print("GOT US A SESSION BOSH: \(session)")
                            acceptDrop = true
                            sessions.append(session)
                        default:
                            print("DROPPED UNKNOWN ENTITY: ", droppedObject)
                        }
                    }
                    return acceptDrop
                }
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
