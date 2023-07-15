//
//  SessionList.swift
//  Astro
//
//  Created by James Wilson on 13/7/2023.
//

import SwiftUI

struct FileList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selection: Set<File.ID>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \File.timestamp, ascending: false)],
        animation: .default)
    private var files: FetchedResults<File>

    var body: some View {
        List(selection: $selection) {
            ForEach(files) { file in
                Label(file.name, systemImage: "doc")
            }
        }
    }
}
