//
//  SessionView.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import SwiftUI

struct TargetView: View {
    var target: Target

    @State private var selectedFiles = Set<File>()
    @State private var sortOrder: [KeyPathComparator<File>] = [
        .init(\.filter, order: SortOrder.forward),
        .init(\.timestamp, order: SortOrder.reverse)
    ]

    @State private var processedImage: NSImage?

    @ObservedObject private var imageProcessor = ImageProcessor()

    var body: some View {
        // yer item's here, do what ye want with it
        HStack {
            FileView(files: target.files as? Set<File> ?? [])
//            Table(files, selection: $selectedFileIDs, sortOrder: $sortOrder) {
//                TableColumn("Filter", value: \.filter!) { file in
//                    Text(file.filter?.localizedCapitalized ?? "N/A")
//                }
//                .width(min: 20.0, ideal: 30.0, max: nil)
//
//                TableColumn("Timestamp", value: \.timestamp) {
//                    Text($0.timestamp.formatted(date: .abbreviated, time: .shortened))
//                }
//                .width(min: 100.0, ideal: 150.0, max: nil)
//
//                TableColumn("Target", value: \.target!.name)
//                    .width(min: 50.0, ideal: 100.0, max: nil)
//
//                TableColumn("Type", value: \.type) { file in
//                    Text(file.type.localizedCapitalized)
//                }
//                .width(min: 20.0, ideal: 50.0, max: nil)
//            }
//            VStack {
//                Image(nsImage: processedImage ?? NSImage())
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 250.0)
//                MultiFileView(fileIDs: selectedFileIDs)
//            }
//                .frame(width: 250.0)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
//                    imageProcessor.setFilesIDs(selectedFileIDs, context: viewContext)
//                    imageProcessor.processFrames { result in
//                        let rep = NSCIImageRep(ciImage: result)
//                        let nsImage = NSImage(size: rep.size)
//                        nsImage.addRepresentation(rep)
//                        self.processedImage = nsImage
//                    }
                }) {
                    Label("Register", systemImage: "square.stack.3d.down.right")
                }
            }
        }
    }
}

extension TargetView {}
