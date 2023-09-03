//
//  FileMetadataInspectorPane.swift
//  Astro
//
//  Created by James Wilson on 3/9/2023.
//

import SwiftUI

struct FileMetadataInspectorPane: View {
    var file: File?
    @State private var selectedKey: String?

    var body: some View {
        Table(sortedItems, selection: $selectedKey) {
            TableColumn("Key", value: \.key)
            TableColumn("Value", value: \.string)
        }
    }
}

extension FileMetadataInspectorPane {
    var sortedItems: [FileMetadata] {
        guard let file,
              let metadata = file.metadata?.allObjects as? [FileMetadata]
        else { return [] }
        return metadata.sorted(by: { $0.key < $1.key })
    }
}
