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
        List(selection: $selectedSession) {
            ForEach(sessionsByType, id: \.self) { calibrationSession in
                switch calibrationSession.type {
                case .calibration:
                    HStack {
                        CalibrationFlatSessionView(session: calibrationSession.session)
                        Spacer()
                    }
                    .dropDestination(for: URL.self) { items, location in
                        let session = calibrationSession.session
                        var acceptDrop = false
                        var droppedSessions = [Session]()
                        print("DROP items=\(items) location=\(location) to=\(session.dateString)")
                        for url in items {
                            guard let droppedObjectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else { continue }
                            let droppedObject = self.viewContext.object(with: droppedObjectID)
                            switch droppedObject {
                            case let session as Session:
                                acceptDrop = true
                                droppedSessions.append(session)
                            default:
                                print("DROPPED UNKNOWN ENTITY: ", droppedObject)
                            }
                        }

                        let calibratedFilters = session.uniqueCalibrationFilterNames
                        for candidateSession in droppedSessions {
                            candidateSession.files?.map { $0 as! File }.forEach { file in
                                guard let fileFilter = file.filter else { return }
                                if calibratedFilters.contains(fileFilter) {
                                    file.calibrationSession = session
                                }
                            }
                        }
                        try! self.viewContext.save()
                        return acceptDrop
                    }

                case .light:
                    HStack {
                        Spacer()
                        CalibrationLightSessionView(session: calibrationSession.session)
                    }
                    .draggable(calibrationSession.session.objectID.uriRepresentation())
                }
            }
        }
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
        let filters = flatFiles.compactMap { $0.filter }
        return Array(Set(filters)).sorted()
    }
}
