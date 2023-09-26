//
//  FileTableView.swift
//  Astro
//
//  Created by James Wilson on 5/8/2023.
//

import SwiftUI

enum FileTableColumns: String, CaseIterable {
    case timestamp
    case target
    case type
    case filter
}

struct FileTable: View {
    var source: FileBrowserSource
    var columns: [FileTableColumns] = FileTableColumns.allCases

    @FetchRequest var files: FetchedResults<File>

    @State private var selectedFileIDs: Set<File.ID> = []
    @State private var sortOrder: [KeyPathComparator<File>]
    @Binding var navStackPath: [File]

    @ObservedObject var imageProcessor: ImageProcessor = .init()
    @State private var processedImage: NSImage?
    @Environment(\.managedObjectContext) private var viewContext

    init(source: FileBrowserSource, columns: [FileTableColumns], navStackPath: Binding<[File]>) {
        self.source = source
        self.columns = columns
        _files = source.fileFetchRequest
        _navStackPath = navStackPath
        _sortOrder = State(initialValue: source.defaultSortOrder)
    }

    func processSelected() {
//        imageProcessor.setFiles(Set(selectedFiles))
//        imageProcessor.processFrames { image in
//            let rep = NSCIImageRep(ciImage: image)
//            let nsImage = NSImage(size: rep.size)
//            nsImage.addRepresentation(rep)
//            processedImage = nsImage
//        }
    }

    var body: some View {
        HStack {
            Table(sortedFiles, selection: $selectedFileIDs, sortOrder: $sortOrder) {
                TableColumn("Timestamp", value: \.timestamp) { file in
                    Text(file.timestamp.formatted(date: .numeric, time: .shortened))
                }
                .width(min: 100)
                .defaultVisibility(columns.contains(.timestamp) ? .visible : .hidden)

                TableColumn("Target", value: \.target!.name)
                    .width(min: 100)
                    .defaultVisibility(columns.contains(.target) ? .visible : .hidden)

                TableColumn("Type", value: \.type) { file in
                    Text(file.type.localizedCapitalized)
                }
                .width(min: 50)
                .defaultVisibility(columns.contains(.type) ? .visible : .hidden)

                TableColumn("Filter", value: \.filter.name) { file in
                    Text(file.filter.name.localizedCapitalized)
                }
                .width(min: 50)
                .defaultVisibility(columns.contains(.filter) ? .visible : .hidden)
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
                if let image = $processedImage.wrappedValue {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                FileGrid(source: .selection(selectedFileIDs.compactMap { viewContext.managedObjectID(forURIRepresentation: $0) }),
                         navStackPath: $navStackPath)
            }
            .frame(width: 250.0)
        }
        .toolbar {
            Button(action: processSelected) {
                Image(systemName: "checkmark.circle.fill")
            }
        }
    }
}

extension FileTable {
    var sortedFiles: [File] {
        files.sorted(using: sortOrder)
    }
}
