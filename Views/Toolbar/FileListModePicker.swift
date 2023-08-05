//
//  FileListModePicker.swift
//  Astro
//
//  Created by James Wilson on 5/8/2023.
//

import SwiftUI

struct FileListModePicker: View {
    enum ViewMode: String, CaseIterable, Identifiable {
        var id: Self { self }
        case table
        case gallery
    }

    @Binding var mode: ViewMode

    var body: some View {
        Picker("Display Mode", selection: $mode) {
            ForEach(ViewMode.allCases) { viewMode in
                viewMode.label
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

extension FileListModePicker.ViewMode {
    var labelContent: (name: String, systemImage: String) {
        switch self {
        case .table:
            return ("Table", "tablecells")
        case .gallery:
            return ("Gallery", "photo")
        }
    }

    var label: some View {
        let content = labelContent
        return Label(content.name, systemImage: content.systemImage)
    }
}
