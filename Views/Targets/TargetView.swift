//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct TargetView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var targetID: Target.ID?
    @FetchRequest(entity: Target.entity(),
                  sortDescriptors: [])
    var results: FetchedResults<Target>

    @State private var selectedFileIDs: Set<File.ID> = []
    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.timestamp, order: SortOrder.reverse)
    ]

    @State private var processedImage: NSImage?

    @ObservedObject private var imageProcessor = ImageProcessor()

    var body: some View {
        // yer item's here, do what ye want with it
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
                Image(nsImage: processedImage ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250.0)
//                MultiFileView(fileIDs: selectedFileIDs)
            }
            .frame(width: 250.0)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    imageProcessor.setFilesIDs(selectedFileIDs, context: viewContext)
                    imageProcessor.processFrames { result in
                        let rep = NSCIImageRep(ciImage: result)
                        let nsImage = NSImage(size: rep.size)
                        nsImage.addRepresentation(rep)
                        self.processedImage = nsImage
                    }
                }) {
                    Label("Register", systemImage: "clear")
                }
            }
        }
    }
}

extension TargetView {
    var target: Target? {
        if let targetID = targetID {
            results.nsPredicate = NSPredicate(format: "id == %@", targetID)
            return results.first
        } else {
            return nil
        }
    }

    var files: [File] {
        guard let target = target,
              let files = target.files
        else {
            return []
        }
        return files.sortedArray(using: [NSSortDescriptor(keyPath: \File.timestamp, ascending: true)]) as! [File]
    }
}
