//
//  CalibrationSessionList.swift
//  Astro
//
//  Created by James Wilson on 17/9/2023.
//

import SwiftUI

struct CalibrationSession {
    let type: SessionType
    let session: Session
}

enum SessionType: String {
    case calibration
    case light
}

extension CalibrationSession: Identifiable {
    var id: URL { session.id.appending(path: type.rawValue) }
}

extension CalibrationSession: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CalibrationSessionList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: true)],
        predicate: NSPredicate(format: "ANY files.type =[cd] %@", "Flat"),
        animation: .default)
    private var calibrationSessions: FetchedResults<Session>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.dateString, ascending: true)],
        predicate: NSPredicate(format: "ANY files.type =[cd] %@", "Light"),
        animation: .default)
    private var lightSessions: FetchedResults<Session>

    @State private var selectedSession: Set<CalibrationSession> = []

    var body: some View {
        Table(sessionsByType) {
            TableColumn("Flats") { calibrationSession in
                if calibrationSession.type == .calibration {
                    CalibrationFlatSessionView(session: calibrationSession.session)
                        .dropDestination(for: URL.self) { items, _ in
                            let session = calibrationSession.session
                            var acceptDrop = false
                            var droppedSessions = [Session]()
                            for url in items {
                                guard let droppedObjectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else { continue }
                                let droppedObject = self.viewContext.object(with: droppedObjectID)
                                switch droppedObject {
                                case let session as Session:
                                    acceptDrop = true
                                    droppedSessions.append(session)
                                default:
                                    break
                                }
                            }
                            let calibratedFilters = session.uniqueCalibrationFilterNames
                            for candidateSession in droppedSessions {
                                candidateSession.files?.map { $0 as! File }.forEach { file in
                                    if calibratedFilters.contains(file.filter.name) {
                                        file.calibrationSession = session
                                    }
                                }
                            }
                            try! self.viewContext.save()
                            return acceptDrop
                        }
                } else {
                    EmptyView()
                }
            }
            TableColumn("Lights") { calibrationSession in
                if calibrationSession.type == .light {
                    CalibrationLightSessionView(session: calibrationSession.session)
                        .background(Color.gray.opacity(-1.0 * Double.infinity)) // Needed to make whole cell draggable
                        .draggable(calibrationSession.session.objectID.uriRepresentation())
                } else {
                    EmptyView()
                }
            }
        }
        .tableColumnHeaders(.hidden)
    }

    var sessionsByType: [CalibrationSession] {
        var sessions = [CalibrationSession]()
        sessions.append(contentsOf: calibrationSessions.map { CalibrationSession(type: .calibration, session: $0) })
        sessions.append(contentsOf: lightSessions.map { CalibrationSession(type: .light, session: $0) })
        return sessions.sorted {
            $0.session.dateString < $1.session.dateString
        }
    }
}

extension Session {
    var uniqueCalibrationFilterNames: [String] {
        guard let files = files?.allObjects as? [File] else { return [] }
        let flatFiles = files.filter {
            $0.type.caseInsensitiveCompare("Flat") == .orderedSame
        }
        let filters = flatFiles.compactMap { $0.filter.name }
        return Array(Set(filters)).sorted()
    }
}
