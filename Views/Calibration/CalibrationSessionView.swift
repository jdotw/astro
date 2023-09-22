//
//  CalibrationSessionView.swift
//  Astro
//
//  Created by James Wilson on 22/9/2023.
//

import SwiftUI

struct CalibrationSessionView: View {
    @ObservedObject var session: Session
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
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
            /* DEBUG */
            for session in sessions {
                session.files?.forEach { file in
                    guard let file = file as? File else { return }
                    if file.filter == "green" {
                        file.calibrationSession = session
                    }
                }
            }
            /* END DEBUG */

            return acceptDrop
        }
    }
}
