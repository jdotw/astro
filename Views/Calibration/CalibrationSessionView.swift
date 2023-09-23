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
            var droppedSessions = [Session]()
            print("DROP items=\(items) location=\(location) to=\(session.dateString)")
            for url in items {
                guard let droppedObjectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else { continue }
                let droppedObject = viewContext.object(with: droppedObjectID)
                switch droppedObject {
                case let session as Session:
                    acceptDrop = true
                    droppedSessions.append(session)
                default:
                    print("DROPPED UNKNOWN ENTITY: ", droppedObject)
                }
            }

            let calibratedFilters = session.uniqueFilterNames
            for candidateSession in droppedSessions {
                candidateSession.files?.map { $0 as! File }.forEach { file in
                    guard let fileFilter = file.filter else { return }
                    if calibratedFilters.contains(fileFilter) {
                        file.calibrationSession = session
                    }
                }
            }
            try! viewContext.save()

            return acceptDrop
        }
    }
}
