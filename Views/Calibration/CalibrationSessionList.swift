//
//  CalibrationSessionList.swift
//  Astro
//
//  Created by James Wilson on 17/9/2023.
//

import SwiftUI

enum SessionType: String {
    case calibration
    case light
}

struct CalibrationSession {
    let type: SessionType
    let session: Session
}

extension CalibrationSession: Identifiable {
    var id: URL {
        session.id.appending(queryItems: [URLQueryItem(name: "type", value: type.rawValue)])
    }
}

extension CalibrationSession: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum CalibrationTableItemType {
    case session
    case filter
}

struct CalibrationTableItem {
    let type: CalibrationTableItemType

    let sessionType: SessionType
    var session: Session

    let filter: Filter?

    let children: [CalibrationTableItem]?

    init(type: CalibrationTableItemType, sessionType: SessionType, session: Session, filter: Filter? = nil, children: [CalibrationTableItem]? = nil) {
        self.type = type
        self.sessionType = sessionType
        self.session = session
        self.filter = filter
        self.children = children
    }

    init?(url: URL, context: NSManagedObjectContext) {
        let store = PersistenceController.shared.container.persistentStoreCoordinator
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let sessionID = store.managedObjectID(forURIRepresentation: url.absoluteURL),
              let session = try? context.existingObject(with: sessionID) as? Session
        else { return nil }
        self.session = session
        self.children = nil

        guard let typeString = components.queryItems?.first(where: { $0.name == "type" })?.value
        else { return nil }
        self.sessionType = SessionType(rawValue: typeString) ?? .light

        if let filterURLString = components.queryItems?.first(where: { $0.name == "filter" })?.value,
           let filterURL = URL(string: filterURLString),
           let filterID = store.managedObjectID(forURIRepresentation: filterURL)
        {
            self.filter = try? context.existingObject(with: filterID) as? Filter
            self.type = .filter
        } else {
            self.type = .session
            self.filter = nil
        }
    }
}

extension CalibrationTableItem: Equatable {
    static func == (lhs: CalibrationTableItem, rhs: CalibrationTableItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension CalibrationTableItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CalibrationTableItem: Identifiable {
    var id: URL {
        var url = session.id.appending(path: sessionType.rawValue)
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "type", value: sessionType.rawValue))
        if let filter {
            let filterURL = filter.objectID.uriRepresentation()
            queryItems.append(URLQueryItem(name: "filter", value: filterURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))
        }

        url.append(queryItems: queryItems)
        return url
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
    @Binding var selectedFilterID: URL?
    @Binding var selectedSessionType: SessionType?

    @State private var selectedItemID: Set<URL> = []
    @State private var selectedItem: Set<CalibrationTableItem> = []

    @State var isExpanded: [URL: Bool] = [:]

    private func binding(for key: URL) -> Binding<Bool> {
        return .init(
            get: { self.isExpanded[key, default: true] },
            set: { self.isExpanded[key] = $0 })
    }

    var body: some View {
        hierarchicalTableBody
            .toolbar(content: {
                Button("Clear Calibration") {
                    let files = try! viewContext.fetch(File.fetchRequest())
                    files.forEach { file in
                        file.calibrationSession = nil
                    }
                    try! viewContext.save()
                }
            })
    }

    var hierarchicalTableBody: some View {
        return Table(of: CalibrationTableItem.self, selection: $selectedItemID) {
            TableColumn("Flat") { item in
                VStack {
                    let session = item.session
                    switch item.type {
                    case .session:
                        switch item.sessionType {
                        case .calibration:
                            CalibrationSessionListSessionView(session: session, sessionType: .calibration)
                        default:
                            EmptyView()
                        }
                    case .filter:
                        let filter = item.filter!
                        switch item.sessionType {
                        case .calibration:
                            CalibrationSessionListFilterView(session: item.session, filter: filter, sessionType: .calibration)

                        default:
                            EmptyView()
                        }
                    }
                }
                .dropDestination(for: URL.self) { droppedURLs, _ in
                    let destinationSession = item.session
                    var acceptDrop = false
                    var droppedItems = [CalibrationTableItem]()
                    for url in droppedURLs {
                        guard let item = CalibrationTableItem(url: url, context: viewContext) else { continue }
                        droppedItems.append(item)
                    }
                    let calibratedFilters = destinationSession.uniqueCalibrationFilterNames
                    for droppedItem in droppedItems {
                        var candidateFiles = droppedItem.session.files?.compactMap { $0 as? File }
                        if droppedItem.type == .filter {
                            candidateFiles = candidateFiles?.filter { $0.filter == droppedItem.filter }
                        }
                        candidateFiles?.forEach { file in
                            if calibratedFilters.contains(file.filter.name) {
                                file.calibrationSession = destinationSession
                                acceptDrop = true
                            }
                        }
                    }
                    try! self.viewContext.save()
                    return acceptDrop
                }
            }

            TableColumn("Light") { item in
                HStack {
                    switch item.type {
                    case .session:
                        let session = item.session
                        switch item.sessionType {
                        case .light:
                            CalibrationSessionListSessionView(session: session, sessionType: .light)
                                .draggable(item.session.objectID.uriRepresentation())
                        default:
                            EmptyView()
                        }
                    case .filter:
                        let filter = item.filter!
                        switch item.sessionType {
                        case .light:
                            CalibrationSessionListFilterView(session: item.session, filter: filter, sessionType: .light)
                                .draggable(item.id)
                        default:
                            EmptyView()
                        }
                    }
                }
            }

        } rows: {
            let tableItems = sessionsByType.map { calibrationSession in
                let files = calibrationSession.session.files?.allObjects as? [File]
                let filtersArray = files?.compactMap { file in
                    switch calibrationSession.type {
                    case .light:
                        if file.type.lowercased() == "light" {
                            return file.filter // Only show the filter if there's light frames for this light session
                        }
                    case .calibration:
                        if file.type.lowercased() == "flat" {
                            return file.filter // Only show the filter if it's used for flat frames in this calibration session
                        }
                    }
                    return nil
                }
                let uniqueFilters = Set(filtersArray ?? [])
                let sortedFilters = uniqueFilters.sorted { a, b in
                    self.sortOrder(forFilter: a, inSession: calibrationSession.session) < self.sortOrder(forFilter: b, inSession: calibrationSession.session)
                }

                return CalibrationTableItem(type: .session,
                                            sessionType: calibrationSession.type,
                                            session: calibrationSession.session,
                                            children: sortedFilters.map { filter in
                                                CalibrationTableItem(type: .filter,
                                                                     sessionType: calibrationSession.type,
                                                                     session: calibrationSession.session,
                                                                     filter: filter)
                                            })
            }

            ForEach(tableItems) { item in
                DisclosureTableRow(item, isExpanded: self.binding(for: item.id)) {
                    ForEach(item.children ?? []) { child in
                        TableRow(child)
                    }
                }
            }
        }
        .tableColumnHeaders(.hidden)
        .onChange(of: selectedItemID) { _, _ in
            var selectedItem: CalibrationTableItem?
            if let selectedItemURL = selectedItemID.first {
                selectedItem = CalibrationTableItem(url: selectedItemURL, context: viewContext)
            }
            selectedSessionID = selectedItem?.session.id
            selectedFilterID = selectedItem?.filter?.id
            selectedSessionType = selectedItem?.sessionType
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

    func sortOrder(forFilter filter: Filter, inSession session: Session) -> Int {
        // Sort order:
        // 100. Calibrated by earlier session
        //      Sorted by: R, G, B, L, Ha, O3, S2
        // 200. Not calibrated
        //      Sorted by: R, G, B, L, Ha, O3, S2
        // 300. Calibrated by older session
        //      Sorted by: R, G, B, L, Ha, O3, S2
        var score = 0
        let filesInSession = session.filesWithFilter(filter)
        if let calSession = filesInSession.calibrationSession {
            if calSession.dateString.compare(session.dateString) != .orderedDescending {
                score = 100 // Calibrated by earlier session (or same date) 100-199
            } else {
                score = 300 // Calibrated by later session 300-399
            }
        } else {
            score = 200 // Not calibrated 200-299
        }
        switch filter.name.lowercased() {
        // RGBL 1-9
        case "red":
            score += 1
        case "green":
            score += 2
        case "blue":
            score += 3
        case "lum":
            score += 4
        // Narrowband 10-19
        case "ha":
            score += 10
        case "o3":
            score += 11
        case "s2":
            score += 12
        // Unknown: 99
        default:
            score += 99
        }
        return score
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

    func filesWithFilter(_ filter: Filter) -> [File] {
        guard let files = files?.allObjects as? [File] else { return [] }
        return files.filter { $0.filter == filter }
    }
}
