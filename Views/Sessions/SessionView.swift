//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct SessionView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var sessionID: Session.ID?
    @FetchRequest(entity: Session.entity(),
                  sortDescriptors: [])
    var results: FetchedResults<Session>

    @State private var selectedFileIDs: Set<File.ID> = []
    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.timestamp, order: SortOrder.reverse)
    ]

    var body: some View {
        HStack {
            Table(files, selection: $selectedFileIDs, sortOrder: $sortOrder) {
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
                MultiFileView(fileIDs: selectedFileIDs)
            }
            .frame(width: 250.0)
        }
    }
}

extension SessionView {
    var session: Session? {
        if let sessionID = sessionID {
            results.nsPredicate = NSPredicate(format: "id == %@", sessionID)
            return results.first
        } else {
            return nil
        }
    }

    var files: [File] {
        guard let session = session,
              let files = session.files
        else {
            return []
        }
        return files.sortedArray(using: [NSSortDescriptor(keyPath: \File.timestamp, ascending: true)]) as! [File]
    }
}
