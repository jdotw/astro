//
//  FileListModePicker.swift
//  Astro
//
//  Created by James Wilson on 5/8/2023.
//

import SwiftUI

struct FileBrowserModePicker: View {
    @Binding var mode: FileBrowserViewMode

    var body: some View {
        Picker("Display Mode", selection: $mode) {
            ForEach(FileBrowserViewMode.allCases) { viewMode in
                viewMode.label
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

extension FileBrowserViewMode {
    var labelContent: (name: String, systemImage: String) {
        switch self {
        case .approve:
            return ("Approve", "checkmark.circle")
        case .grid:
            return ("Grid", "photo.on.rectangle.angled")
        case .table:
            return ("Table", "list.dash")
        }
    }

    var label: some View {
        let content = labelContent
        return Label(content.name, systemImage: content.systemImage)
    }
}
