//
//  FileView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

struct MultiFileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var exposureValue: Double = 0
    var fileIDs: Set<File.ID>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \File.timestamp, ascending: false)],
        animation: .default)
    private var files: FetchedResults<File>

    var allFiles: [File] {
        files.nsPredicate = NSPredicate(format: "id IN %@", fileIDs)
        return files.map { $0 }
    }

    var body: some View {
        if fileIDs.count > 1 {
            VStack { Text("Multiple files selected") }
        } else {
            VStack {
                SingleFileView(fileID: fileIDs.first)
            }
        }
    }
}
