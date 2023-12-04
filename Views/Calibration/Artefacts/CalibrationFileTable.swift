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

struct CalibrationFileTable: View {
    @FetchRequest var files: FetchedResults<File>

    @State private var selectedFileIDs: Set<File.ID> = []
    @State private var sortOrder: [KeyPathComparator<File>]
    @Binding var navStackPath: [File]

    @Environment(\.managedObjectContext) private var viewContext

    init(navStackPath: Binding<[File]>) {
        let types = [FileType.bias.rawValue, FileType.dark.rawValue, FileType.flat.rawValue]
        let status = [FileStatus.master.rawValue]
        let predicate = NSPredicate(format: "typeRawValue IN %@ AND statusRawValue IN %@", types, status)
        let sortDescriptors = [NSSortDescriptor(keyPath: \File.timestamp, ascending: true)]
        _files = FetchRequest<File>(entity: File.entity(),
                                    sortDescriptors: sortDescriptors,
                                    predicate: predicate)
        _sortOrder = State(initialValue: [.init(\.timestamp, order: SortOrder.forward)])
        _navStackPath = navStackPath
    }

    var body: some View {
        HStack {
            Table(sortedFiles, selection: $selectedFileIDs, sortOrder: $sortOrder) {
                TableColumn("Timestamp", value: \.timestamp) { file in
                    Text(file.timestamp.formatted(date: .numeric, time: .shortened))
                }
                .width(min: 100)

                TableColumn("Type", value: \.typeRawValue) { file in
                    Text(file.typeRawValue.localizedCapitalized)
                }
                .width(min: 50)

                TableColumn("Status", value: \.typeRawValue) { file in
                    Text(file.statusRawValue.localizedCapitalized)
                }
                .width(min: 50)

                TableColumn("Filter", value: \.filter.name) { file in
                    Text(file.filter.name.localizedCapitalized)
                }
                .width(min: 50)
            }
            .contextMenu(forSelectionType: File.ID.self, menu: { _ in
                //                    Button("Rename", action: { print("RENAME \(items)") })
                //                    Button("Delete", action: { print("DELETE \(items)") })
            }, primaryAction: { _ in
                if selectedFileIDs.count == 1,
                   let selectedFile = files.first(where: { $0.id == selectedFileIDs.first })
                {
                    navStackPath.append(selectedFile)
                }
            })
            VStack {
                FileGrid(source: .selection(selectedFileIDs.compactMap { viewContext.managedObjectID(forURIRepresentation: $0) }),
                         navStackPath: $navStackPath)
            }
            .frame(width: 250.0)
        }
    }
}

extension CalibrationFileTable {
    var sortedFiles: [File] {
        files.sorted(using: sortOrder)
    }
}
