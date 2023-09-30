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

enum CalibrationTableItemType {
    case session
    case filter
}

struct CalibrationTableItem: Identifiable, Hashable {
    static func == (lhs: CalibrationTableItem, rhs: CalibrationTableItem) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    let type: CalibrationTableItemType
    
    let sessionType: SessionType
    let session: Session
    
    let filter: Filter?
    
    let children: [CalibrationTableItem]?
    
    init(type: CalibrationTableItemType, sessionType: SessionType, session: Session, filter: Filter? = nil, children: [CalibrationTableItem]? = nil) {
        self.id = UUID()
        self.type = type
        self.sessionType = sessionType
        self.session = session
        self.filter = filter
        self.children = children
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
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
    
    @Binding var selectedSessionID: URL?
    
    @State private var selectedItemID: Set<UUID> = []
    
    @State private var tableItems: [CalibrationTableItem] = []
    @State var isExpanded: [UUID: Bool] = [:]
    
    func createTableItems() {
        tableItems = sessionsByType.map { calibrationSession in
            let filtersArray = (calibrationSession.session.files?.allObjects as? [File])?.compactMap { file in
                file.filter
            }
            let filters = Set(filtersArray ?? [])
            return CalibrationTableItem(type: .session,
                                        sessionType: calibrationSession.type,
                                        session: calibrationSession.session,
                                        children: filters.map { filter in
                                            CalibrationTableItem(type: .filter,
                                                                 sessionType: calibrationSession.type,
                                                                 session: calibrationSession.session,
                                                                 filter: filter)
                                        })
        }
    }
    
    private func binding(for key: UUID) -> Binding<Bool> {
        return .init(
            get: { self.isExpanded[key, default: true] },
            set: { self.isExpanded[key] = $0 })
    }
    
    var body: some View {
        hierarchicalTableBody
            .onAppear {
                createTableItems()
            }
    }
    
    var hierarchicalTableBody: some View {
        return Table(of: CalibrationTableItem.self, selection: $selectedItemID) {
            //        return Table(tableItems, children: \.children) {
            TableColumn("Flat") { item in
//                VStack {
                let session = item.session
                switch item.type {
                case .session:
                    switch item.sessionType {
                    case .calibration:
                        Text(session.dateString)
                    default:
                        EmptyView()
                    }
                case .filter:
                    let filter = item.filter!
                    switch item.sessionType {
                    case .calibration:
                        Text(filter.name)
                    default:
                        EmptyView()
                    }
                }
//                }
//                .draggable(item.session.objectID.uriRepresentation())
            }
            TableColumn("Light") { item in
                VStack {
                    switch item.type {
                    case .session:
                        let session = item.session
                        switch item.sessionType {
                        case .light:
                            Text(session.dateString)
                        default:
                            EmptyView()
                        }
                    case .filter:
                        let filter = item.filter!
                        switch item.sessionType {
                        case .light:
                            Text(filter.name)
                        default:
                            EmptyView()
                        }
                    }
                }
//                .draggable(item.session.objectID.uriRepresentation())
            }
            
        } rows: {
            ForEach(tableItems) { item in
                //                DisclosureTableRow(item, isExpanded: item.isExpanded) {
                //                    ForEach(item.children) { child in
                //                        TableRow(child)
                //                    }
                //                }
                DisclosureTableRow(item, isExpanded: self.binding(for: item.id)) {
                    ForEach(item.children ?? []) { child in
                        TableRow(child)
                    }
                }
            }
        }
        .tableColumnHeaders(.hidden)
        .onChange(of: selectedItemID) { _, newValue in
            print("newValue: \(newValue)")
            selectedSessionID = selectedSession?.id
        }
    }
    
    var gridBody: some View {
        ScrollView {
            Grid {
                ForEach(sessionsByType) { calSess in
                    GridRow {
                        switch calSess.type {
                        case .calibration:
                            Text(calSess.session.dateString)
                            EmptyView()
                        case .light:
                            EmptyView()
                            Text(calSess.session.dateString)
                        }
                    }
                }
            }
        }
    }
    
    var tableBody: some View {
        Table(sessionsByType) {
            TableColumn("Flats") { calibrationSession in
                if calibrationSession.type == .calibration {
                    CalibrationFlatSessionView(session: calibrationSession.session)
                        .background(Color.gray.opacity(0.5)) // Needed to make whole cell draggable
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
                            print("DROP: session.uniqueCalibrationFilterNames=\(calibratedFilters)")
                            for candidateSession in droppedSessions {
                                let candidateFiles = candidateSession.files?.map { $0 as! File }
                                print("FILES: \(candidateFiles)")
                                candidateFiles?.forEach { file in
                                    if calibratedFilters.contains(file.filter.name) {
                                        file.calibrationSession = session
                                    }
                                }
                            }
                            try! self.viewContext.save()
                            return acceptDrop
                        }
                } else {
                    EmptyView().listRowInsets(.none)
                }
            }
            TableColumn("Lights") { calibrationSession in
                if calibrationSession.type == .light {
                    CalibrationLightSessionView(session: calibrationSession.session)
                        .background(Color.gray.opacity(0.5)) // Needed to make whole cell draggable
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
    
    var selectedSession: Session? {
        guard let selectedItemID = selectedItemID.first else { return nil }
        for item in tableItems {
            if item.id == selectedItemID { return item.session }
            if let children = item.children {
                for child in children {
                    if child.id == selectedItemID { return child.session }
                }
            }
        }
        return nil
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
