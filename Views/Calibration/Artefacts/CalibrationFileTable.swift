//
//  CalibrationFileTable.swift
//  Astro
//
//  Created by James Wilson on 3/12/2023.
//

import SwiftUI

enum CalibrationFileTableColumns: String, CaseIterable {
    case timestamp
    case target
    case type
    case filter
}

enum CalibrationFileTableItemType: String, CaseIterable {
    case filter
    case file
}

struct CalibrationFileTableItem: Identifiable {
    var type: CalibrationFileTableItemType
    var id: URL
    var filter: Filter?
    var file: File?

    init(filter: Filter) {
        self.type = .filter
        self.id = filter.id
        self.filter = filter
    }

    init(file: File) {
        self.type = .file
        self.id = file.id
        self.file = file
    }

    var timestamp: Date? {
        switch type {
        case .file:
            return file?.timestamp ?? Date()
        case .filter:
            return nil
        }
    }

    var name: String {
        switch type {
        case .file:
            return file?.name ?? ""
        case .filter:
            return filter?.name ?? ""
        }
    }
}

struct CalibrationFileTable: View {
    @ObservedObject var session: Session
    @Binding var navStackPath: [File]

    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedFileIDs: Set<File.ID> = []
    //    @State private var sortOrder: [KeyPathComparator<CalibrationFileTableItem>] = [.init(\.timestamp, order: SortOrder.forward), .init(\.name, order: SortOrder.forward)]
    @State private var sortOrder: [KeyPathComparator<CalibrationFileTableItem>] = [.init(\.name, order: SortOrder.forward)]

    @FetchRequest(entity: Session.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Session.date, ascending: false)],
                  predicate: NSPredicate(format: "SUBQUERY(files, $file, $file.typeRawValue IN %@).@count > 0", [FileType.flat.rawValue, FileType.bias.rawValue, FileType.dark.rawValue]))
    var calibrationSessions: FetchedResults<Session>

    @FetchRequest var filesInSession: FetchedResults<File>

    init(session: Session, navStackPath: Binding<[File]>) {
        self.session = session
        _navStackPath = navStackPath
        _filesInSession = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \File.name, ascending: true)],
            predicate: NSPredicate(format: "session = %@", session),
            animation: .default)
    }

    @State private var isExpanded: [URL: Bool] = [:]
    private func binding(for key: URL) -> Binding<Bool> {
        return .init(
            get: {
                let isExpandedByDefault = false
                return self.isExpanded[key, default: isExpandedByDefault]
            },
            set: { self.isExpanded[key] = $0 })
    }

    private func calibrationSessionBinding(_ filter: Filter, type: FileType) -> Binding<URL?> {
        return .init(
            get: {
                session.resolvedCalibrationSession(forFilter: filter, type: type)?.id
            },
            set: {
                var calibrationSession: Session?
                if let url = $0,
                   let objectID = viewContext.managedObjectID(forURIRepresentation: url)
                {
                    calibrationSession = viewContext.object(with: objectID) as? Session
                }
                session.setCalibration(session: calibrationSession, forFilter: filter, type: type)
                do {
                    try viewContext.save()
                } catch {
                    fatalError(error.localizedDescription)
                }

            })
    }

    private func filterPicker(_ title: String?, filter: Filter, type: FileType) -> some View {
        let calSessionsForFilter = calibrationSessions.calibrationSessions(forFilter: filter, ofType: type)
        return Picker(selection: calibrationSessionBinding(filter, type: type)) {
            ForEach(calSessionsForFilter) { session in
                let candidateDate = session.date
                let sessionDate = self.session.date
                let deltaDays = Int(candidateDate.timeIntervalSince(sessionDate) / 86400)
                let sign = deltaDays.signum() == 1 ? "+" : "-"
                let label = "\(session.dateString) - \(sign)\(abs(deltaDays)) days"
                Text(label).tag(session.id as URL?)
            }
            Text("None").tag(nil as URL?)
        } label: {
            if let title {
                Text(title)
            } else {
                EmptyView()
            }
        }
    }

    private func filterRowView(_ title: String, filter: Filter, fileType: FileType) -> some View {
        return VStack {
            Text(title)
            HStack {
                VStack {
                    Text("IMAGE1")
                    filterPicker(nil, filter: filter, type: fileType)
                }
                VStack {
                    Text("IMAGE2")
                    filterPicker(nil, filter: filter, type: fileType)
                }
            }
        }
    }

    private func filterRowView(_ filter: Filter) -> some View {
        return VStack {
            HStack {
                Text(filter.name.localizedCapitalized).font(.title3)
                Spacer()
            }
            HStack {
                VStack {
                    Text("Earlier")
                    Spacer()
                    CalibrationSessionPicker(session: self.session, filter: filter, fileType: .flat, limit: .earlier)
                    Spacer()
                }
                VStack {
                    Text("Reference")
                    Spacer()
                    CalibrationReferenceImagePicker(session: self.session, filter: filter)
                    Spacer()
                }
                VStack {
                    Text("Later")
                    Spacer()
                    CalibrationSessionPicker(session: self.session, filter: filter, fileType: .flat, limit: .later)
                    Spacer()
                }
                VStack {
                    HStack {
                        Text("Dark")
                        CalibrationSessionPicker(session: self.session, filter: filter, fileType: .dark, limit: .none)
                    }
                    HStack {
                        Text("Bias")
                        CalibrationSessionPicker(session: self.session, filter: filter, fileType: .bias, limit: .none)
                    }
                }
            }
        }.padding()
//        return CalibrationSessionFilterLightView(session: session, filter: filter)

//        return VStack {
//            HStack {
//                Text(filter.name.localizedCapitalized)
//                Spacer()
//            }
//            Spacer()
//            HStack {
//                filterRowView("Flat Session", filter: filter, fileType: .flat)
//                filterRowView("Dark Session", filter: filter, fileType: .dark)
//                filterRowView("Bias Session", filter: filter, fileType: .bias)
//            }
//        }
    }

    private var hierarchicalFileTable: some View {
        Table(of: CalibrationFileTableItem.self, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { item in
                switch item.type {
                case .file:
                    Text(item.file?.name ?? "")
                case .filter:
                    if let filter = item.filter {
                        filterRowView(filter)
                    } else {
                        Text(item.name)
                    }
                }
            }
        } rows: {
            let filters = Array(Set(files.compactMap { $0.filter }))
            let filterItems = filters.map { filter in
                CalibrationFileTableItem(filter: filter)
            }
            ForEach(filterItems.sorted(using: sortOrder)) { filter in
                DisclosureTableRow(filter, isExpanded: binding(for: filter.id)) {
                    let filterFiles = files.filter { $0.filter == filter.filter }
                    ForEach(filterFiles) { file in
                        TableRow(CalibrationFileTableItem(file: file))
                    }
                }
            }
        }
    }

    var body: some View {
        HStack {
            hierarchicalFileTable
            VStack {
                FileGrid(source: .selection(selectedFileIDs.compactMap { viewContext.managedObjectID(forURIRepresentation: $0) }),
                         navStackPath: $navStackPath)
            }
            .frame(width: 250.0)
        }
    }
}

extension CalibrationFileTable {
    var files: [File] {
        return filesInSession.map { $0 }
    }
}

extension FetchedResults<Session> {
    func calibrationSessions(forFilter filter: Filter, ofType type: FileType) -> [Session] {
        return self.filter { session in
            let files = session.files?.allObjects as? [File] ?? []
            return files.contains { file in
                // We only care if the filter matches if we
                // are being asked for flat calibration sessions.
                // Dark and bias calibration frames do not have an
                // affinity to a filter (because they're dark) and
                // therefore we will match on any filter so long as
                // the file type matches
                file.typeRawValue == type.rawValue && (type != .flat || file.filter == filter)
            }
        }
    }
}
