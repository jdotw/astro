//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct SessionView: View {
    var session: Session

    @State private var selectedFileIDs: Set<File.ID> = []
    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.timestamp, order: SortOrder.reverse)
    ]

    var body: some View {
        VStack {
            HStack {
                Table(files ?? [], selection: $selectedFileIDs, sortOrder: $sortOrder) {
                    TableColumn("Timestamp", value: \.timestamp) {
                        Text($0.timestamp.formatted(date: .omitted, time: .shortened))
                    }
                    .width(100)

                    TableColumn("Target", value: \.target!.name)
                        .width(100)

                    TableColumn("Type", value: \.type) { file in
                        Text(file.type.localizedCapitalized)
                    }
                    .width(50)

                    TableColumn("Filter", value: \.filter!) { file in
                        Text(file.filter?.localizedCapitalized ?? "N/A")
                    }
                    .width(50)
                }
                VStack {
                    MultiFileView(files: selectedFiles)
                }
                .frame(width: 250.0)
            }
        }
    }
}

extension SessionView {
    var files: [File]? {
        guard let files = session.files as? Set<File>
        else {
            return nil
        }
        return files.sorted(using: sortOrder)
    }

    var selectedFiles: Set<File> {
        if let files = session.files as? Set<File> {
            return files.filter { selectedFileIDs.contains($0.id) }
        } else {
            return []
        }
    }
}
