//
//  FileMetadataInspectorPane.swift
//  Astro
//
//  Created by James Wilson on 3/9/2023.
//

import SwiftUI

struct MetadataKeyValue {
    let key: String
    let value: String
}

struct FileMetadataInspectorPane: View {
    var file: File?
    @State private var selectedKey: String?

    var body: some View {
        Table(sortedKeyValues, selection: $selectedKey) {
            TableColumn("Key") { item in
                Text(item.key)
            }
            TableColumn("Value") { item in
                Text(item.value)
            }
        }
    }
}

extension FileMetadataInspectorPane {
    var sortedKeyValues: [MetadataKeyValue] {
        return [
            MetadataKeyValue(key: "Test Key", value: "Test Value"),
            MetadataKeyValue(key: "Pier", value: "West"),
            MetadataKeyValue(key: "Camera", value: "QSI683"),
        ]
    }
}

extension MetadataKeyValue: Identifiable {
    var id: String { key }
}
